using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.DailyPlan;
using Menzilim.Application.DTOs.Projects;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// Günlük planın ana görevi ile Living Project adımı arasındaki bağı ve
/// tamamlama senkronizasyonunu gerçek HTTP akışıyla test eder.
/// </summary>
public sealed class DailyPlanProjectLinkTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public DailyPlanProjectLinkTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    private async Task<string> RegisterWithProfileAsync(
        string specializationName = "Backend",
        int dailyMinutes = 60)
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"link-{Guid.NewGuid():N}@menzilim.test",
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
            dailyLearningMinutes = dailyMinutes,
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

    private async Task<DailyPlanResponse> GetPlanAsync(string token)
    {
        var response = await SendAsync(HttpMethod.Get, "/api/daily-plan/me", token);
        response.EnsureSuccessStatusCode();

        return (await response.Content.ReadFromJsonAsync<DailyPlanResponse>())!;
    }

    [Fact]
    public async Task DailyPlan_MainTask_IsNextProjectStep()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        var plan = await GetPlanAsync(token);
        var main = plan.Tasks.First();

        Assert.Equal("Project", main.TaskType);
        Assert.Equal(project.NextStep!.Id, main.UserProjectStepId);
        Assert.Equal(project.NextStep.Title, main.Title);
        Assert.Equal(project.Id, main.UserProjectId);
        Assert.Equal(project.Name, main.ProjectName);
        Assert.Equal(1, main.ProjectStepOrder);
        Assert.Equal(project.TotalSteps, main.ProjectTotalSteps);
    }

    [Fact]
    public async Task DailyPlan_UsesStepMinutes_AndStaysWithinDailyBudget()
    {
        var token = await RegisterWithProfileAsync(dailyMinutes: 60);
        var project = await GetProjectAsync(token);

        var plan = await GetPlanAsync(token);
        var main = plan.Tasks.First();

        Assert.Equal(project.NextStep!.EstimatedMinutes, main.EstimatedMinutes);
        Assert.Equal(60, plan.Tasks.Sum(t => t.EstimatedMinutes));
        Assert.Equal(60, plan.TotalMinutes);
    }

    [Fact]
    public async Task DailyPlan_ShortDay_NeverExceedsDailyBudget()
    {
        var token = await RegisterWithProfileAsync(dailyMinutes: 30);

        var plan = await GetPlanAsync(token);

        Assert.Equal(30, plan.Tasks.Sum(t => t.EstimatedMinutes));
        Assert.All(plan.Tasks, task => Assert.True(task.EstimatedMinutes > 0));
    }

    [Fact]
    public async Task DailyPlan_IsStable_NoDuplicateTaskForSameStep()
    {
        var token = await RegisterWithProfileAsync();

        var first = await GetPlanAsync(token);
        var second = await GetPlanAsync(token);

        Assert.Equal(first.Id, second.Id);
        Assert.Equal(first.Tasks.Count, second.Tasks.Count);

        var stepIds = second.Tasks
            .Where(t => t.UserProjectStepId is not null)
            .Select(t => t.UserProjectStepId)
            .ToList();

        Assert.Single(stepIds);
        Assert.Equal(stepIds.Count, stepIds.Distinct().Count());
    }

    [Fact]
    public async Task CompletingStep_CompletesLinkedDailyTask()
    {
        var token = await RegisterWithProfileAsync();

        var plan = await GetPlanAsync(token);
        var main = plan.Tasks.First();

        Assert.False(main.IsCompleted);

        (await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{main.UserProjectStepId}/complete",
            token)).EnsureSuccessStatusCode();

        var updated = await GetPlanAsync(token);
        var updatedMain = updated.Tasks.Single(t => t.Id == main.Id);

        Assert.True(updatedMain.IsCompleted);
        Assert.NotNull(updatedMain.CompletedAt);
        Assert.True(updated.CompletedMinutes >= updatedMain.EstimatedMinutes);
    }

    [Fact]
    public async Task CompletingDailyTask_DoesNotCompleteProjectStep()
    {
        var token = await RegisterWithProfileAsync();

        var plan = await GetPlanAsync(token);
        var main = plan.Tasks.First();

        (await SendAsync(
            HttpMethod.Post,
            $"/api/daily-plan/tasks/{main.Id}/complete",
            token)).EnsureSuccessStatusCode();

        var project = await GetProjectAsync(token);

        // Proje adımı tek doğruluk kaynağıdır: görev tamamlandı diye açılmaz.
        Assert.Equal(
            UserProjectStepStatus.Available,
            project.Steps[0].Status);

        Assert.Equal(0, project.CompletedSteps);
    }

    [Fact]
    public async Task CompletingStepTwice_DoesNotUnlockTwoSteps()
    {
        var token = await RegisterWithProfileAsync();

        // Günün planı üretilir: adım ile görev arasında bağ oluşur.
        await GetPlanAsync(token);

        var project = await GetProjectAsync(token);
        var stepId = project.Steps[0].Id;

        (await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{stepId}/complete",
            token)).EnsureSuccessStatusCode();

        // Aynı adım ikinci kez gönderilir.
        (await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{stepId}/complete",
            token)).EnsureSuccessStatusCode();

        var updated = await GetProjectAsync(token);

        Assert.Equal(1, updated.CompletedSteps);
        Assert.Equal(
            UserProjectStepStatus.Available,
            updated.Steps[1].Status);

        Assert.Equal(
            UserProjectStepStatus.Locked,
            updated.Steps[2].Status);

        // Bağlı görev de yalnızca bir kez tamamlanır.
        await using var db = _factory.CreateDbContext();
        var tasks = await db.DailyTasks
            .Where(t => t.UserProjectStepId == stepId)
            .ToListAsync();

        Assert.Single(tasks);
        Assert.True(tasks[0].IsCompleted);
    }

    [Fact]
    public async Task CompletingOtherUsersStep_DoesNotTouchDailyTasks()
    {
        var ownerToken = await RegisterWithProfileAsync();
        var ownerPlan = await GetPlanAsync(ownerToken);
        var ownerTask = ownerPlan.Tasks.First();

        var otherToken = await RegisterWithProfileAsync("Frontend");

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{ownerTask.UserProjectStepId}/complete",
            otherToken);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        var unchanged = await GetPlanAsync(ownerToken);

        Assert.False(unchanged.Tasks.Single(t => t.Id == ownerTask.Id).IsCompleted);
    }

    [Fact]
    public async Task ProjectCompleted_PlanFallsBackToLearnTask()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        // Tüm adımlar tamamlanır.
        foreach (var step in project.Steps)
        {
            (await SendAsync(
                HttpMethod.Post,
                $"/api/projects/me/steps/{step.Id}/complete",
                token)).EnsureSuccessStatusCode();
        }

        // Yeni bir gün için plan üretilir (bugünkü plan silinir).
        await using (var db = _factory.CreateDbContext())
        {
            db.DailyPlans.RemoveRange(await db.DailyPlans.ToListAsync());
            await db.SaveChangesAsync();
        }

        var plan = await GetPlanAsync(token);

        Assert.DoesNotContain(plan.Tasks, t => t.TaskType == "Project");
        Assert.Equal("Learn", plan.Tasks.First().TaskType);
    }
}
