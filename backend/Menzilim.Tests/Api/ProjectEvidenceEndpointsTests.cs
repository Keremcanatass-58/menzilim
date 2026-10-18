using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Progress;
using Menzilim.Application.DTOs.Projects;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// Adım kanıtı (bağlantı + not), adım-quiz eşleştirmesi ve süreklilik
/// uçlarını gerçek HTTP akışıyla test eder.
/// </summary>
public sealed class ProjectEvidenceEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public ProjectEvidenceEndpointsTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    private async Task<string> RegisterWithProfileAsync(
        string specializationName = "Backend")
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"proof-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });

        register.EnsureSuccessStatusCode();

        var token = (await register.Content
            .ReadFromJsonAsync<AuthResponse>())!.Token;

        Guid professionId, specializationId;
        await using (var db = _factory.CreateDbContext())
        {
            var spec = await db.Specializations
                .SingleAsync(s => s.Name == specializationName);

            professionId = spec.ProfessionId;
            specializationId = spec.Id;
        }

        (await SendAsync(HttpMethod.Post, "/api/onboarding", token, new
        {
            professionId,
            specializationId,
            experienceLevel = "Beginner",
            careerGoal = "Backend geliştirici olmak",
            dailyLearningMinutes = 60,
        })).EnsureSuccessStatusCode();

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
        {
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", token);
        }

        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }

        return await _client.SendAsync(request);
    }

    private async Task<UserProjectResponse> GetProjectAsync(string token)
    {
        var response = await SendAsync(HttpMethod.Get, "/api/projects/me", token);
        response.EnsureSuccessStatusCode();

        var projects = await response
            .Content.ReadFromJsonAsync<List<UserProjectResponse>>();

        return Assert.Single(projects!);
    }

    [Fact]
    public async Task Evidence_RequiresAuthorization()
    {
        var response = await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{Guid.NewGuid()}/evidence",
            body: new { evidenceUrl = "https://github.com/x/y" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Evidence_IsSavedAndReturned()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);
        var step = project.Steps[0];

        var response = await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{step.Id}/evidence",
            token,
            new
            {
                evidenceUrl = "https://github.com/kullanici/proje",
                note = "Gereksinimleri README'ye yazdım.",
            });

        response.EnsureSuccessStatusCode();

        var updated = await response
            .Content.ReadFromJsonAsync<UserProjectResponse>();

        var updatedStep = updated!.Steps.Single(s => s.Id == step.Id);

        Assert.Equal("https://github.com/kullanici/proje", updatedStep.EvidenceUrl);
        Assert.Equal("Gereksinimleri README'ye yazdım.", updatedStep.Note);

        // Kalıcı: yeniden okunduğunda da gelir.
        var reloaded = await GetProjectAsync(token);
        Assert.Equal(
            "https://github.com/kullanici/proje",
            reloaded.Steps.Single(s => s.Id == step.Id).EvidenceUrl);
    }

    [Fact]
    public async Task Evidence_CanBeAddedBeforeAndAfterCompletion()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);
        var step = project.Steps[0];

        // Tamamlama kanıt istemez.
        (await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{step.Id}/complete",
            token)).EnsureSuccessStatusCode();

        // Tamamlandıktan sonra kanıt eklenebilir.
        var response = await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{step.Id}/evidence",
            token,
            new { evidenceUrl = "https://example.com/commit" });

        response.EnsureSuccessStatusCode();

        var updated = await response
            .Content.ReadFromJsonAsync<UserProjectResponse>();

        var updatedStep = updated!.Steps.Single(s => s.Id == step.Id);

        Assert.Equal(UserProjectStepStatus.Completed, updatedStep.Status);
        Assert.NotNull(updatedStep.CompletedAt);
        Assert.Equal("https://example.com/commit", updatedStep.EvidenceUrl);
    }

    [Fact]
    public async Task Evidence_EmptyValuesClearFields()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);
        var step = project.Steps[0];

        (await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{step.Id}/evidence",
            token,
            new { evidenceUrl = "https://github.com/x/y", note = "not" }))
            .EnsureSuccessStatusCode();

        var response = await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{step.Id}/evidence",
            token,
            new { evidenceUrl = "   ", note = (string?)null });

        response.EnsureSuccessStatusCode();

        var updated = await response
            .Content.ReadFromJsonAsync<UserProjectResponse>();

        var updatedStep = updated!.Steps.Single(s => s.Id == step.Id);

        Assert.Null(updatedStep.EvidenceUrl);
        Assert.Null(updatedStep.Note);
    }

    [Theory]
    [InlineData("github.com/kullanici/proje")]
    [InlineData("javascript:alert(1)")]
    [InlineData("ftp://dosya.example.com")]
    public async Task Evidence_InvalidUrl_ReturnsBadRequest(string url)
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        var response = await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{project.Steps[0].Id}/evidence",
            token,
            new { evidenceUrl = url });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        // Kayıt değişmemiştir.
        var unchanged = await GetProjectAsync(token);
        Assert.Null(unchanged.Steps[0].EvidenceUrl);
    }

    [Fact]
    public async Task Evidence_OtherUsersStep_ReturnsNotFound()
    {
        var ownerToken = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(ownerToken);

        var otherToken = await RegisterWithProfileAsync("Frontend");

        var response = await SendAsync(
            HttpMethod.Put,
            $"/api/projects/me/steps/{project.Steps[0].Id}/evidence",
            otherToken,
            new { evidenceUrl = "https://github.com/saldiri/deneme" });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        var unchanged = await GetProjectAsync(ownerToken);
        Assert.Null(unchanged.Steps[0].EvidenceUrl);
    }

    [Fact]
    public async Task ProjectCompletion_SetsStatusAndDate()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        UserProjectResponse? updated = null;

        foreach (var step in project.Steps)
        {
            var response = await SendAsync(
                HttpMethod.Post,
                $"/api/projects/me/steps/{step.Id}/complete",
                token);

            response.EnsureSuccessStatusCode();

            updated = await response
                .Content.ReadFromJsonAsync<UserProjectResponse>();
        }

        Assert.Equal(UserProjectStatus.Completed, updated!.Status);
        Assert.NotNull(updated.StartedAt);
        Assert.NotNull(updated.CompletedAt);
        Assert.Equal(updated.TotalSteps, updated.CompletedSteps);
        Assert.All(updated.Steps, step => Assert.NotNull(step.CompletedAt));
    }

    [Fact]
    public async Task Steps_LinkQuizBySkill_WithoutWrongMatches()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        // Quiz'i olan adımlar, adımın kendi becerisine bağlı quiz'i taşır.
        await using var db = _factory.CreateDbContext();

        foreach (var step in project.Steps.Where(s => s.QuizId is not null))
        {
            var quiz = await db.Quizzes.SingleAsync(q => q.Id == step.QuizId);

            Assert.Equal(step.SkillId, quiz.SkillId);
            Assert.True(quiz.IsActive);
            Assert.Equal(quiz.Title, step.QuizTitle);
        }

        // Becerisi olmayan adımda quiz olmaz.
        Assert.All(
            project.Steps.Where(s => s.SkillId is null),
            step => Assert.Null(step.QuizId));
    }

    [Fact]
    public async Task Streak_RequiresAuthorization()
    {
        var response = await SendAsync(HttpMethod.Get, "/api/progress/streak/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Streak_NewUser_IsZero()
    {
        var token = await RegisterWithProfileAsync();

        var response = await SendAsync(
            HttpMethod.Get, "/api/progress/streak/me", token);

        response.EnsureSuccessStatusCode();

        var streak = await response.Content.ReadFromJsonAsync<StreakResponse>();

        Assert.Equal(0, streak!.CurrentStreak);
        Assert.Equal(0, streak.LongestStreak);
        Assert.False(streak.IsActiveToday);
        Assert.Null(streak.LastActiveDate);
        Assert.Equal(UserTimeZone.DefaultOffsetMinutes, streak.TimeZoneOffsetMinutes);
    }

    [Fact]
    public async Task Streak_CountsTodayOnceForMultipleActivities()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        // Aynı gün iki adım tamamlanır.
        (await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{project.Steps[0].Id}/complete",
            token)).EnsureSuccessStatusCode();

        (await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{project.Steps[1].Id}/complete",
            token)).EnsureSuccessStatusCode();

        var response = await SendAsync(
            HttpMethod.Get, "/api/progress/streak/me", token);

        var streak = await response.Content.ReadFromJsonAsync<StreakResponse>();

        Assert.Equal(1, streak!.CurrentStreak);
        Assert.Equal(1, streak.LongestStreak);
        Assert.True(streak.IsActiveToday);

        // Sonuç UserProgress'e yazılır.
        await using var db = _factory.CreateDbContext();
        var progress = await db.UserProgresses.SingleAsync();

        Assert.Equal(1, progress.CurrentStreak);
        Assert.Equal(1, progress.LongestStreak);
    }

    [Fact]
    public async Task TimeZone_IsStoredAndUsed()
    {
        var token = await RegisterWithProfileAsync();

        var response = await SendAsync(
            HttpMethod.Put,
            "/api/profile/timezone",
            token,
            new { offsetMinutes = -300 });

        response.EnsureSuccessStatusCode();

        var streak = await (await SendAsync(
            HttpMethod.Get, "/api/progress/streak/me", token))
            .Content.ReadFromJsonAsync<StreakResponse>();

        Assert.Equal(-300, streak!.TimeZoneOffsetMinutes);
    }

    [Fact]
    public async Task TimeZone_InvalidValue_KeepsPrevious()
    {
        var token = await RegisterWithProfileAsync();

        (await SendAsync(
            HttpMethod.Put, "/api/profile/timezone", token,
            new { offsetMinutes = 120 })).EnsureSuccessStatusCode();

        (await SendAsync(
            HttpMethod.Put, "/api/profile/timezone", token,
            new { offsetMinutes = 100000 })).EnsureSuccessStatusCode();

        var streak = await (await SendAsync(
            HttpMethod.Get, "/api/progress/streak/me", token))
            .Content.ReadFromJsonAsync<StreakResponse>();

        Assert.Equal(120, streak!.TimeZoneOffsetMinutes);
    }
}
