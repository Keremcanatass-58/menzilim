using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Content;
using Menzilim.Application.DTOs.Quiz;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// Temiz bir veritabanında uygulama açılış seed'i (Program.cs) sonrasında
/// günlük plan, öneri ve quiz uçlarının içerikle dolu döndüğünü doğrular.
/// </summary>
public sealed class SeedContentEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public SeedContentEndpointsTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    private async Task<string> RegisterWithProfileAsync(string specializationName, int minutes)
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"seed-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });
        register.EnsureSuccessStatusCode();
        var token = (await register.Content.ReadFromJsonAsync<AuthResponse>())!.Token;

        Guid professionId, specializationId;
        await using (var db = _factory.CreateDbContext())
        {
            var spec = await db.Specializations.SingleAsync(s => s.Name == specializationName);
            professionId = spec.ProfessionId;
            specializationId = spec.Id;

            // Bu testler günlük plan davranışını her uzmanlık için ölçer;
            // release'e hazırlık kapısı (IsAvailable) kapsam dışıdır.
            var profession = await db.Professions.SingleAsync(p => p.Id == professionId);
            profession.IsAvailable = true;
            await db.SaveChangesAsync();
        }

        (await SendAsync(HttpMethod.Post, "/api/onboarding", token, new
        {
            professionId,
            specializationId,
            experienceLevel = "Beginner",
            careerGoal = $"{specializationName} geliştirici olmak",
            dailyLearningMinutes = minutes,
        })).EnsureSuccessStatusCode();

        return token;
    }

    private async Task<HttpResponseMessage> SendAsync(
        HttpMethod method, string url, string? token = null, object? body = null)
    {
        using var request = new HttpRequestMessage(method, url);
        if (token is not null)
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null)
            request.Content = JsonContent.Create(body);
        return await _client.SendAsync(request);
    }

    private async Task<List<JsonElement>> GetPlanTasksAsync(string token)
    {
        var response = await SendAsync(HttpMethod.Get, "/api/daily-plan/me", token);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var plan = await response.Content.ReadFromJsonAsync<JsonElement>();
        return plan.GetProperty("tasks").EnumerateArray().ToList();
    }

    private static Guid? ContentIdOf(JsonElement task) =>
        task.GetProperty("contentId").ValueKind == JsonValueKind.Null
            ? null
            : task.GetProperty("contentId").GetGuid();

    private async Task<HashSet<Guid>> ContentIdsLinkedToSpecializationAsync(string specializationName)
    {
        await using var db = _factory.CreateDbContext();

        var skillIds = await db.SpecializationSkills
            .Where(ss => ss.Specialization.Name == specializationName)
            .Select(ss => ss.SkillId)
            .ToListAsync();

        return (await db.ContentSkills
                .Where(cs => skillIds.Contains(cs.SkillId))
                .Select(cs => cs.ContentId)
                .ToListAsync())
            .ToHashSet();
    }

    // Yeni kullanıcı için ilk iki içerik, uzmanlığın temel öğrenme sırasıdır.
    [Theory]
    [InlineData("Frontend", "Learn HTML", "JavaScript Guide")]
    [InlineData("Backend", "A tour of the C# language", "SQL Tutorial")]
    [InlineData("Full Stack", "JavaScript Guide", "TypeScript Handbook")]
    [InlineData("Mobile", "Introduction to Dart", "Your first Flutter app")]
    public async Task DailyPlan_60Minutes_HasLearnPracticeQuiz_WithSpecializationContent(
        string specialization,
        string expectedLearnTitle,
        string expectedPracticeTitle)
    {
        var token = await RegisterWithProfileAsync(specialization, 60);

        var tasks = await GetPlanTasksAsync(token);

        Assert.Equal(
            new[] { "Learn", "Practice", "Quiz" },
            tasks.Select(t => t.GetProperty("taskType").GetString()));

        var learnContentId = ContentIdOf(tasks[0]);
        var practiceContentId = ContentIdOf(tasks[1]);

        Assert.NotNull(learnContentId);
        Assert.NotNull(practiceContentId);
        Assert.NotEqual(learnContentId, practiceContentId);
        Assert.Null(ContentIdOf(tasks[2]));

        // Seçilen içerikler kullanıcının uzmanlık skill'lerine bağlı.
        var specContent = await ContentIdsLinkedToSpecializationAsync(specialization);
        Assert.Contains(learnContentId!.Value, specContent);
        Assert.Contains(practiceContentId!.Value, specContent);

        await using var db = _factory.CreateDbContext();
        Assert.Equal(expectedLearnTitle, (await db.Contents.FindAsync(learnContentId))!.Title);
        Assert.Equal(expectedPracticeTitle, (await db.Contents.FindAsync(practiceContentId))!.Title);
    }

    [Fact]
    public async Task DailyPlan_30Minutes_HasLearnWithContent()
    {
        var token = await RegisterWithProfileAsync("Backend", 30);

        var tasks = await GetPlanTasksAsync(token);

        Assert.Equal(
            new[] { "Learn", "Quiz" },
            tasks.Select(t => t.GetProperty("taskType").GetString()));
        Assert.NotNull(ContentIdOf(tasks[0]));
    }

    [Theory]
    [InlineData("Frontend")]
    [InlineData("Backend")]
    [InlineData("Full Stack")]
    [InlineData("Mobile")]
    public async Task Recommendations_ReturnSeededContent(string specialization)
    {
        var token = await RegisterWithProfileAsync(specialization, 60);

        var response = await SendAsync(HttpMethod.Get, "/api/content/recommendations", token);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var recommendations =
            await response.Content.ReadFromJsonAsync<List<ContentRecommendationResponse>>();

        Assert.NotEmpty(recommendations!);

        var seededTitles = ContentSeeder.Contents.Select(c => c.Title).ToHashSet();
        Assert.All(recommendations!, r =>
        {
            Assert.Contains(r.Title, seededTitles);
            Assert.StartsWith("https://", r.Url);
            Assert.False(string.IsNullOrWhiteSpace(r.RecommendationReason));
        });
    }

    [Fact]
    public async Task ContentWriteEndpoints_RequireAuthentication()
    {
        var create = await _client.PostAsJsonAsync("/api/content", new
        {
            title = "Anonim içerik",
            url = "https://example.com/anonim",
            source = "Test",
            publishedAt = DateTime.UtcNow,
            readingTimeMinutes = 5,
            level = "Beginner",
        });

        var assign = await _client.PostAsJsonAsync("/api/content/profession", new
        {
            contentId = Guid.NewGuid(),
            professionId = Guid.NewGuid(),
        });

        Assert.Equal(HttpStatusCode.Unauthorized, create.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, assign.StatusCode);

        // Katalog anonim yazmaya kapalı.
        await using var db = _factory.CreateDbContext();
        Assert.False(await db.Contents.AnyAsync(c => c.Title == "Anonim içerik"));
    }

    [Fact]
    public async Task Quizzes_ListsAllSeededQuizzes_AndActiveQuizStaysAspNet()
    {
        var all = await _client.GetFromJsonAsync<List<QuizSummaryResponse>>("/api/quizzes");

        Assert.Equal(1 + ContentSeeder.Quizzes.Count, all!.Count);
        Assert.All(all, q => Assert.True(q.QuestionCount >= 3));
        Assert.All(ContentSeeder.Quizzes, d => Assert.Contains(all, q => q.Title == d.Title));

        // Birden fazla quiz varken varsayılan (günlük görev) quiz'i deterministik.
        var active = await _client.GetFromJsonAsync<QuizDetailResponse>("/api/quizzes/active");
        Assert.Equal("ASP.NET Core Temelleri", active!.Title);
    }

    private async Task<string> QuizTitleAsync(Guid quizId)
    {
        await using var db = _factory.CreateDbContext();
        return (await db.Quizzes.SingleAsync(q => q.Id == quizId)).Title;
    }

    private static Guid? QuizIdOf(JsonElement task) =>
        task.GetProperty("quizId").ValueKind == JsonValueKind.Null
            ? null
            : task.GetProperty("quizId").GetGuid();

    [Theory]
    [InlineData("Frontend", "JavaScript ve Web Temelleri")]
    [InlineData("Backend", "Entity Framework Core ve SQL Temelleri")]
    [InlineData("Full Stack", "REST API Temelleri")]
    [InlineData("Mobile", "Flutter ve Dart Temelleri")]
    public async Task DailyPlan_QuizTask_PointsToSpecializationQuiz(
        string specialization,
        string expectedQuizTitle)
    {
        var token = await RegisterWithProfileAsync(specialization, 60);

        var tasks = await GetPlanTasksAsync(token);

        var quiz = tasks.Single(t => t.GetProperty("taskType").GetString() == "Quiz");
        var quizId = QuizIdOf(quiz);
        Assert.NotNull(quizId);
        Assert.Equal(expectedQuizTitle, await QuizTitleAsync(quizId!.Value));

        // Yalnızca Quiz görevinde dolu; diğer görevlerin sözleşmesi aynı.
        Assert.All(
            tasks.Where(t => t.GetProperty("taskType").GetString() != "Quiz"),
            t => Assert.Null(QuizIdOf(t)));

        // Aynı gün tekrar istendiğinde (mevcut plan) aynı quiz.
        var again = await GetPlanTasksAsync(token);
        Assert.Equal(
            quizId,
            QuizIdOf(again.Single(t => t.GetProperty("taskType").GetString() == "Quiz")));
    }

    [Theory]
    [InlineData("SOC")]
    [InlineData("Data Analyst")]
    public async Task DailyPlan_QuizTask_FallsBackToDefaultQuiz_WhenNoSpecializationQuiz(
        string specialization)
    {
        var token = await RegisterWithProfileAsync(specialization, 60);

        var tasks = await GetPlanTasksAsync(token);

        var quizId = QuizIdOf(tasks.Single(t => t.GetProperty("taskType").GetString() == "Quiz"));
        Assert.NotNull(quizId);
        Assert.Equal("ASP.NET Core Temelleri", await QuizTitleAsync(quizId!.Value));
    }

    [Fact]
    public async Task DailyPlan_QuizTask_SubmitAndComplete_KeepsWorking()
    {
        var token = await RegisterWithProfileAsync("Frontend", 60);
        var quizTask = (await GetPlanTasksAsync(token))
            .Single(t => t.GetProperty("taskType").GetString() == "Quiz");
        var quizId = QuizIdOf(quizTask)!.Value;

        // Görevdeki quizId mevcut quiz API'siyle açılır ve çözülür.
        var detail = await _client.GetFromJsonAsync<QuizDetailResponse>($"/api/quizzes/{quizId}");
        Assert.Equal("JavaScript ve Web Temelleri", detail!.Title);

        var definition = ContentSeeder.Quizzes.Single(q => q.Title == detail.Title);
        var answers = detail.Questions.Select(q => new
        {
            questionId = q.Id,
            selectedOption = definition.Questions.Single(d => d.Text == q.Text).CorrectOption,
        }).ToList();

        var submit = await SendAsync(
            HttpMethod.Post, $"/api/quizzes/{quizId}/submit", token, new { answers });
        Assert.Equal(HttpStatusCode.OK, submit.StatusCode);
        Assert.Equal(100, (await submit.Content.ReadFromJsonAsync<QuizSubmitResultResponse>())!.Score);

        // Günlük görev tamamlanır; yanıt aynı quizId'yi korur.
        var complete = await SendAsync(
            HttpMethod.Post,
            $"/api/daily-plan/tasks/{quizTask.GetProperty("id").GetString()}/complete",
            token);
        Assert.Equal(HttpStatusCode.OK, complete.StatusCode);

        var plan = await complete.Content.ReadFromJsonAsync<JsonElement>();
        var completedQuiz = plan.GetProperty("tasks").EnumerateArray()
            .Single(t => t.GetProperty("taskType").GetString() == "Quiz");
        Assert.True(completedQuiz.GetProperty("isCompleted").GetBoolean());
        Assert.Equal(quizId, QuizIdOf(completedQuiz));

        // Quiz skoru ilgili skill'in ilerlemesine yansır.
        var skills = await SendAsync(HttpMethod.Get, "/api/skills/me", token);
        var javaScript = (await skills.Content.ReadFromJsonAsync<JsonElement>())
            .EnumerateArray()
            .Single(s => s.GetProperty("skillName").GetString() == "JavaScript");
        Assert.Equal(100, javaScript.GetProperty("bestQuizScore").GetInt32());
    }

    [Fact]
    public async Task SeededQuiz_CanBeSubmitted_WithCorrectAnswers()
    {
        var token = await RegisterWithProfileAsync("Mobile", 60);
        var definition = ContentSeeder.Quizzes.Single(q => q.SkillName == "Flutter");

        Guid quizId;
        List<(Guid Id, string Text)> questions;
        await using (var db = _factory.CreateDbContext())
        {
            var quiz = await db.Quizzes
                .Include(q => q.Questions)
                .SingleAsync(q => q.Title == definition.Title);
            quizId = quiz.Id;
            questions = quiz.Questions.Select(q => (q.Id, q.Text)).ToList();
        }

        var answers = questions.Select(q => new
        {
            questionId = q.Id,
            selectedOption = definition.Questions.Single(d => d.Text == q.Text).CorrectOption,
        }).ToList();

        var response = await SendAsync(
            HttpMethod.Post, $"/api/quizzes/{quizId}/submit", token, new { answers });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<QuizSubmitResultResponse>();
        Assert.Equal(100, result!.Score);
        Assert.Equal(definition.Questions.Length, result.TotalQuestions);
    }
}
