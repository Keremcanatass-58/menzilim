using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// /api/daily-plan/me ve /api/daily-plan/tasks/{id}/complete uçlarını gerçek
/// HTTP akışıyla (JWT, register, onboarding) test eder.
/// </summary>
public sealed class DailyPlanEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public DailyPlanEndpointsTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    private async Task<string> RegisterWithProfileAsync(int minutes = 60)
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"plan-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });
        register.EnsureSuccessStatusCode();
        var token = (await register.Content.ReadFromJsonAsync<AuthResponse>())!.Token;

        Guid professionId, specializationId;
        await using (var db = _factory.CreateDbContext())
        {
            var spec = await db.Specializations.SingleAsync(s => s.Name == "Backend");
            professionId = spec.ProfessionId;
            specializationId = spec.Id;
        }

        (await SendAsync(HttpMethod.Post, "/api/onboarding", token, new
        {
            professionId,
            specializationId,
            experienceLevel = "Beginner",
            careerGoal = "Backend geliştirici olmak",
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

    private async Task<JsonElement> GetPlanAsync(string token)
    {
        var response = await SendAsync(HttpMethod.Get, "/api/daily-plan/me", token);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return await response.Content.ReadFromJsonAsync<JsonElement>();
    }

    private static string TaskId(JsonElement plan, string type) =>
        plan.GetProperty("tasks").EnumerateArray()
            .Single(t => t.GetProperty("taskType").GetString() == type)
            .GetProperty("id").GetString()!;

    private static string[] TaskTypes(JsonElement plan) =>
        plan.GetProperty("tasks").EnumerateArray()
            .Select(t => t.GetProperty("taskType").GetString()!)
            .ToArray();

    [Fact]
    public async Task CompleteTask_ReturnsFullPlan_WithExistingContract()
    {
        var token = await RegisterWithProfileAsync(60);
        var plan = await GetPlanAsync(token);
        var learnId = TaskId(plan, "Learn");

        var response = await SendAsync(
            HttpMethod.Post, $"/api/daily-plan/tasks/{learnId}/complete", token);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // Plan alanları (mevcut sözleşme).
        foreach (var field in new[] { "id", "date", "title", "isCompleted", "totalMinutes", "completedMinutes", "tasks" })
            Assert.True(body.TryGetProperty(field, out _), $"eksik alan: {field}");

        Assert.Equal(plan.GetProperty("id").GetString(), body.GetProperty("id").GetString());
        Assert.False(body.GetProperty("isCompleted").GetBoolean());
        Assert.Equal(60, body.GetProperty("totalMinutes").GetInt32());

        // Tüm görevler, deterministik sırada.
        Assert.Equal(new[] { "Learn", "Practice", "Quiz" }, TaskTypes(body));

        var tasks = body.GetProperty("tasks").EnumerateArray().ToList();
        foreach (var field in new[] { "id", "title", "description", "taskType", "estimatedMinutes", "isCompleted", "completedAt", "contentId" })
            Assert.All(tasks, t => Assert.True(t.TryGetProperty(field, out _), $"eksik görev alanı: {field}"));

        var learn = tasks[0];
        Assert.True(learn.GetProperty("isCompleted").GetBoolean());
        Assert.NotEqual(JsonValueKind.Null, learn.GetProperty("completedAt").ValueKind);
        Assert.Equal(learn.GetProperty("estimatedMinutes").GetInt32(), body.GetProperty("completedMinutes").GetInt32());
        Assert.All(tasks.Skip(1), t => Assert.False(t.GetProperty("isCompleted").GetBoolean()));
    }

    [Fact]
    public async Task CompletingAllTasks_PlanBecomesCompleted_AndGetReturnsAllTasksInOrder()
    {
        var token = await RegisterWithProfileAsync(90);
        var plan = await GetPlanAsync(token);
        Assert.Equal(new[] { "Learn", "Practice", "Quiz", "Review" }, TaskTypes(plan));

        foreach (var type in new[] { "Learn", "Practice", "Quiz" })
        {
            (await SendAsync(HttpMethod.Post, $"/api/daily-plan/tasks/{TaskId(plan, type)}/complete", token))
                .EnsureSuccessStatusCode();

            var partial = await GetPlanAsync(token);
            Assert.False(partial.GetProperty("isCompleted").GetBoolean());
            Assert.Equal(new[] { "Learn", "Practice", "Quiz", "Review" }, TaskTypes(partial));
        }

        var last = await SendAsync(
            HttpMethod.Post, $"/api/daily-plan/tasks/{TaskId(plan, "Review")}/complete", token);
        var lastBody = await last.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(lastBody.GetProperty("isCompleted").GetBoolean());

        var final = await GetPlanAsync(token);
        Assert.True(final.GetProperty("isCompleted").GetBoolean());
        Assert.Equal(90, final.GetProperty("completedMinutes").GetInt32());
    }

    [Fact]
    public async Task CompletingAnotherUsersTask_Returns403_AndOwnersPlanIsUnchanged()
    {
        var owner = await RegisterWithProfileAsync(60);
        var intruder = await RegisterWithProfileAsync(60);
        var ownerPlan = await GetPlanAsync(owner);

        var response = await SendAsync(
            HttpMethod.Post, $"/api/daily-plan/tasks/{TaskId(ownerPlan, "Learn")}/complete", intruder);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

        var after = await GetPlanAsync(owner);
        Assert.All(after.GetProperty("tasks").EnumerateArray(),
            t => Assert.False(t.GetProperty("isCompleted").GetBoolean()));
    }

    [Fact]
    public async Task CompletingTaskTwice_Returns200_AndKeepsFirstCompletionTime()
    {
        var token = await RegisterWithProfileAsync(60);
        var plan = await GetPlanAsync(token);
        var url = $"/api/daily-plan/tasks/{TaskId(plan, "Quiz")}/complete";

        var first = await (await SendAsync(HttpMethod.Post, url, token)).Content.ReadFromJsonAsync<JsonElement>();
        var secondResponse = await SendAsync(HttpMethod.Post, url, token);
        Assert.Equal(HttpStatusCode.OK, secondResponse.StatusCode);
        var second = await secondResponse.Content.ReadFromJsonAsync<JsonElement>();

        // Not: Yeni atanan değer "Z" ile, DB'den okunan değer "Z"siz serialize
        // ediliyor (önceden var olan DateTimeKind farkı). Zamanın kendisi aynı olmalı.
        string CompletedAt(JsonElement p) => p.GetProperty("tasks").EnumerateArray()
            .Single(t => t.GetProperty("taskType").GetString() == "Quiz")
            .GetProperty("completedAt").GetString()!
            .TrimEnd('Z');

        Assert.Equal(CompletedAt(first), CompletedAt(second));
        Assert.False(second.GetProperty("isCompleted").GetBoolean());
        Assert.Equal(3, second.GetProperty("tasks").GetArrayLength());
    }

    [Fact]
    public async Task CompletingUnknownTask_Returns404_AndWithoutToken401()
    {
        var token = await RegisterWithProfileAsync(60);

        var unknown = await SendAsync(
            HttpMethod.Post, $"/api/daily-plan/tasks/{Guid.NewGuid()}/complete", token);
        Assert.Equal(HttpStatusCode.NotFound, unknown.StatusCode);

        var anonymous = await SendAsync(
            HttpMethod.Post, $"/api/daily-plan/tasks/{Guid.NewGuid()}/complete");
        Assert.Equal(HttpStatusCode.Unauthorized, anonymous.StatusCode);
    }
}
