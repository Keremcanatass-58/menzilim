using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Content;
using Menzilim.Application.DTOs.Skills;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// /api/skills/me ve /api/specializations/{id}/skills uçlarını gerçek HTTP
/// akışıyla (register → onboarding → içerik/quiz aktivitesi) test eder.
/// </summary>
public sealed class SkillEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public SkillEndpointsTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    // ---------- yardımcılar ----------

    private async Task<string> RegisterAsync()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"skill-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });

        response.EnsureSuccessStatusCode();

        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>();
        return auth!.Token;
    }

    private async Task<Specialization> GetSpecializationAsync(string name)
    {
        await using var db = _factory.CreateDbContext();
        return await db.Specializations.SingleAsync(s => s.Name == name);
    }

    private async Task<string> RegisterWithProfileAsync(string specializationName = "Backend")
    {
        var token = await RegisterAsync();
        var specialization = await GetSpecializationAsync(specializationName);

        var response = await SendAsync(HttpMethod.Post, "/api/onboarding", token, new
        {
            professionId = specialization.ProfessionId,
            specializationId = specialization.Id,
            experienceLevel = "Beginner",
            careerGoal = "Backend geliştirici olmak",
            dailyLearningMinutes = 30,
        });

        response.EnsureSuccessStatusCode();
        return token;
    }

    private async Task<HttpResponseMessage> SendAsync(
        HttpMethod method,
        string url,
        string? token = null,
        object? body = null)
    {
        using var request = new HttpRequestMessage(method, url);

        if (token is not null)
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        if (body is not null)
            request.Content = JsonContent.Create(body);

        return await _client.SendAsync(request);
    }

    private async Task<Guid> CreateContentLinkedToAsync(string skillName)
    {
        // Sayımlar yalnızca testin kendi içeriğine göre yapılsın: açılışta
        // seed'lenen örnek içerikler devre dışı bırakılır.
        await using (var seeded = _factory.CreateDbContext())
        {
            await seeded.Contents.ExecuteUpdateAsync(
                s => s.SetProperty(c => c.IsActive, false));
        }

        // Katalog yazma ucu artık kimlik doğrulaması ister.
        var token = await RegisterAsync();

        var response = await SendAsync(HttpMethod.Post, "/api/content", token, new CreateContentRequest
        {
            Title = "ASP.NET Core Web API Development",
            Description = "Learn the basics of building Web APIs with ASP.NET Core.",
            Url = "https://learn.microsoft.com/aspnet/core/web-api/",
            Source = "Microsoft Learn",
            PublishedAt = new DateTime(2026, 9, 17),
            ReadingTimeMinutes = 10,
            Level = "Beginner",
        });

        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadFromJsonAsync<ContentResponse>();

        await using var db = _factory.CreateDbContext();
        var skill = await db.Skills.SingleAsync(s => s.Name == skillName);
        db.ContentSkills.Add(new ContentSkill
        {
            Id = Guid.NewGuid(),
            ContentId = content!.Id,
            SkillId = skill.Id,
        });
        await db.SaveChangesAsync();

        return content.Id;
    }

    private async Task SubmitAspNetQuizAsync(string token, bool allCorrect)
    {
        await using var db = _factory.CreateDbContext();
        var quiz = await db.Quizzes
            .Include(q => q.Questions)
            .SingleAsync(q => q.Title == "ASP.NET Core Temelleri");

        var answers = quiz.Questions
            .Select((q, i) => new
            {
                questionId = q.Id,
                // Seed'deki tüm doğru cevaplar "A".
                selectedOption = allCorrect || i == 0 ? q.CorrectOption : "B",
            })
            .ToList();

        var response = await SendAsync(
            HttpMethod.Post, $"/api/quizzes/{quiz.Id}/submit", token, new { answers });

        response.EnsureSuccessStatusCode();
    }

    private async Task<List<SkillProgressResponse>> GetMySkillsAsync(string token)
    {
        var response = await SendAsync(HttpMethod.Get, "/api/skills/me", token);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<List<SkillProgressResponse>>())!;
    }

    // ---------- /api/skills/me ----------

    [Fact]
    public async Task SkillsMe_WithoutToken_Returns401()
    {
        var response = await _client.GetAsync("/api/skills/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SkillsMe_WithoutOnboardingProfile_Returns404()
    {
        var token = await RegisterAsync();

        var response = await SendAsync(HttpMethod.Get, "/api/skills/me", token);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Kullanıcı profili bulunamadı.", body.GetProperty("message").GetString());
    }

    [Fact]
    public async Task SkillsMe_ReturnsOnlySpecializationSkills_WithZeroProgress()
    {
        var token = await RegisterWithProfileAsync("Backend");

        var skills = await GetMySkillsAsync(token);

        Assert.Equal(
            SkillSeeder.SpecializationSkills["Backend"].OrderBy(n => n, StringComparer.Ordinal),
            skills.Select(s => s.SkillName));
        Assert.All(skills, s => Assert.Equal(0, s.ProgressPercent));

        // Başka uzmanlığa ait skill'ler görünmez.
        Assert.DoesNotContain(skills, s => s.SkillName is "Python" or "React" or "Linux");
    }

    [Fact]
    public async Task SkillsMe_ReflectsOwnContentAndQuizActivity_WithAllFields()
    {
        var token = await RegisterWithProfileAsync("Backend");
        var contentId = await CreateContentLinkedToAsync("ASP.NET Core");

        (await SendAsync(HttpMethod.Post, $"/api/content/{contentId}/complete", token))
            .EnsureSuccessStatusCode();
        await SubmitAspNetQuizAsync(token, allCorrect: false); // 1/3 → 33
        await SubmitAspNetQuizAsync(token, allCorrect: true);  // 3/3 → 100

        var response = await SendAsync(HttpMethod.Get, "/api/skills/me", token);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();

        var aspNet = json.EnumerateArray()
            .Single(e => e.GetProperty("skillName").GetString() == "ASP.NET Core");

        // İçerik %100 + quiz en iyi skor 100 → 100
        Assert.Equal(100, aspNet.GetProperty("progressPercent").GetInt32());
        Assert.Equal("Web", aspNet.GetProperty("category").GetString());
        Assert.Equal(1, aspNet.GetProperty("totalContentCount").GetInt32());
        Assert.Equal(1, aspNet.GetProperty("completedContentCount").GetInt32());
        Assert.Equal(0, aspNet.GetProperty("inProgressContentCount").GetInt32());
        Assert.Equal(1, aspNet.GetProperty("totalQuizCount").GetInt32());
        Assert.Equal(1, aspNet.GetProperty("attemptedQuizCount").GetInt32());
        Assert.Equal(2, aspNet.GetProperty("quizAttemptCount").GetInt32());
        Assert.Equal(100, aspNet.GetProperty("bestQuizScore").GetInt32());
        Assert.Equal(100, aspNet.GetProperty("latestQuizScore").GetInt32());
        Assert.True(Guid.TryParse(aspNet.GetProperty("skillId").GetString(), out _));

        // Aktivitesi olmayan skill'de skorlar null.
        var sql = json.EnumerateArray()
            .Single(e => e.GetProperty("skillName").GetString() == "SQL");
        Assert.Equal(JsonValueKind.Null, sql.GetProperty("bestQuizScore").ValueKind);
        Assert.Equal(JsonValueKind.Null, sql.GetProperty("latestQuizScore").ValueKind);
    }

    [Fact]
    public async Task SkillsMe_IgnoresOtherUsersActivity()
    {
        var contentId = await CreateContentLinkedToAsync("ASP.NET Core");

        var other = await RegisterWithProfileAsync("Backend");
        (await SendAsync(HttpMethod.Post, $"/api/content/{contentId}/complete", other))
            .EnsureSuccessStatusCode();
        await SubmitAspNetQuizAsync(other, allCorrect: true);

        var me = await RegisterWithProfileAsync("Backend");
        var aspNet = (await GetMySkillsAsync(me)).Single(s => s.SkillName == "ASP.NET Core");

        Assert.Equal(0, aspNet.ProgressPercent);
        Assert.Equal(0, aspNet.CompletedContentCount);
        Assert.Equal(0, aspNet.QuizAttemptCount);
        Assert.Null(aspNet.BestQuizScore);
    }

    [Fact]
    public async Task SkillsMe_HidesInactiveSkills()
    {
        var token = await RegisterWithProfileAsync("Backend");

        await using (var db = _factory.CreateDbContext())
        {
            var sql = await db.Skills.SingleAsync(s => s.Name == "SQL");
            sql.IsActive = false;
            await db.SaveChangesAsync();
        }

        var skills = await GetMySkillsAsync(token);

        Assert.DoesNotContain(skills, s => s.SkillName == "SQL");
        Assert.Equal(SkillSeeder.SpecializationSkills["Backend"].Length - 1, skills.Count);
    }

    // ---------- /api/specializations/{id}/skills ----------

    [Fact]
    public async Task SpecializationSkills_ReturnsActiveSkills_SortedByName()
    {
        var specialization = await GetSpecializationAsync("Data Science");

        await using (var db = _factory.CreateDbContext())
        {
            var python = await db.Skills.SingleAsync(s => s.Name == "Python");
            python.IsActive = false;
            await db.SaveChangesAsync();
        }

        var skills = (await _client.GetFromJsonAsync<List<SkillResponse>>(
            $"/api/specializations/{specialization.Id}/skills"))!;

        var expected = SkillSeeder.SpecializationSkills["Data Science"]
            .Where(n => n != "Python")
            .OrderBy(n => n, StringComparer.Ordinal);

        Assert.Equal(expected, skills.Select(s => s.Name));
        Assert.All(skills, s => Assert.False(string.IsNullOrEmpty(s.Category)));
        Assert.Contains(skills, s => s.Name == "İstatistik");
    }

    [Fact]
    public async Task SpecializationSkills_UnknownSpecialization_Returns404()
    {
        var response = await _client.GetAsync(
            $"/api/specializations/{Guid.NewGuid()}/skills");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Uzmanlık bulunamadı.", body.GetProperty("message").GetString());
    }
}
