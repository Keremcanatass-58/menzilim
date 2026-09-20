using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Projects;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// Living Project uçlarını gerçek HTTP akışıyla (JWT, onboarding, seed edilen
/// proje şablonları) test eder.
/// </summary>
public sealed class ProjectEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public ProjectEndpointsTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    private async Task<string> RegisterAsync()
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"project-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });

        register.EnsureSuccessStatusCode();

        return (await register.Content.ReadFromJsonAsync<AuthResponse>())!.Token;
    }

    private async Task<string> RegisterWithProfileAsync(
        string specializationName = "Backend")
    {
        var token = await RegisterAsync();

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
    public async Task ProjectsMe_RequiresAuthorization()
    {
        var response = await SendAsync(HttpMethod.Get, "/api/projects/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task CompleteStep_RequiresAuthorization()
    {
        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{Guid.NewGuid()}/complete");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ProjectsMe_WithoutOnboarding_ReturnsNotFound()
    {
        var token = await RegisterAsync();

        var response = await SendAsync(HttpMethod.Get, "/api/projects/me", token);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Theory]
    [InlineData("Frontend")]
    [InlineData("Backend")]
    [InlineData("Full Stack")]
    [InlineData("Mobile")]
    public async Task ProjectsMe_CreatesProjectForSpecialization(
        string specialization)
    {
        var token = await RegisterWithProfileAsync(specialization);

        var project = await GetProjectAsync(token);

        Assert.False(string.IsNullOrWhiteSpace(project.Name));
        Assert.InRange(project.TotalSteps, 6, 8);
        Assert.Equal(UserProjectStatus.NotStarted, project.Status);
        Assert.Equal(0, project.CompletedSteps);
        Assert.Equal(0, project.ProgressPercent);

        // Yalnızca ilk adım açıktır.
        Assert.Equal(
            UserProjectStepStatus.Available,
            project.Steps[0].Status);

        Assert.All(
            project.Steps.Skip(1),
            step => Assert.Equal(UserProjectStepStatus.Locked, step.Status));

        Assert.NotNull(project.NextStep);
        Assert.Equal(project.Steps[0].Id, project.NextStep!.Id);

        // Adımlar sıralıdır ve süre taşır.
        Assert.Equal(
            project.Steps.Select(s => s.Order).OrderBy(o => o),
            project.Steps.Select(s => s.Order));

        Assert.All(project.Steps, step => Assert.True(step.EstimatedMinutes > 0));

        // En az bir adım gerçek içerikle ilişkilidir.
        Assert.Contains(project.Steps, step => step.ContentId is not null);
    }

    [Fact]
    public async Task ProjectsMe_IsIdempotent_DoesNotCreateSecondProject()
    {
        var token = await RegisterWithProfileAsync();

        var first = await GetProjectAsync(token);
        var second = await GetProjectAsync(token);

        Assert.Equal(first.Id, second.Id);
    }

    [Fact]
    public async Task CompleteStep_UnlocksNextStep_AndUpdatesProgress()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{project.Steps[0].Id}/complete",
            token);

        response.EnsureSuccessStatusCode();

        var updated = await response
            .Content.ReadFromJsonAsync<UserProjectResponse>();

        Assert.Equal(
            UserProjectStepStatus.Completed,
            updated!.Steps[0].Status);

        Assert.Equal(
            UserProjectStepStatus.Available,
            updated.Steps[1].Status);

        Assert.Equal(UserProjectStatus.InProgress, updated.Status);
        Assert.Equal(1, updated.CompletedSteps);
        Assert.True(updated.ProgressPercent > 0);
        Assert.NotNull(updated.StartedAt);
        Assert.Equal(updated.Steps[1].Id, updated.NextStep!.Id);
    }

    [Fact]
    public async Task CompleteStep_LockedStep_ReturnsBadRequest()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{project.Steps[2].Id}/complete",
            token);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        // Durum değişmemiştir.
        var unchanged = await GetProjectAsync(token);
        Assert.Equal(UserProjectStepStatus.Locked, unchanged.Steps[2].Status);
        Assert.Equal(UserProjectStatus.NotStarted, unchanged.Status);
    }

    [Fact]
    public async Task CompleteStep_SyncsContentProgress()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        // İçerikle ilişkili ilk adıma kadar sırayla ilerlenir.
        var target = project.Steps.First(s => s.ContentId is not null);

        foreach (var step in project.Steps.Where(s => s.Order <= target.Order))
        {
            (await SendAsync(
                HttpMethod.Post,
                $"/api/projects/me/steps/{step.Id}/complete",
                token)).EnsureSuccessStatusCode();
        }

        await using var db = _factory.CreateDbContext();

        var progress = await db.UserContentProgresses
            .SingleOrDefaultAsync(p => p.ContentId == target.ContentId);

        Assert.NotNull(progress);
        Assert.True(progress!.IsCompleted);
    }

    [Fact]
    public async Task CompleteAllSteps_MarksProjectCompleted()
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
        Assert.Equal(updated.TotalSteps, updated.CompletedSteps);
        Assert.Equal(100, updated.ProgressPercent);
        Assert.Null(updated.NextStep);
        Assert.NotNull(updated.CompletedAt);
    }

    [Fact]
    public async Task ProjectDetail_OtherUsersProject_ReturnsNotFound()
    {
        var ownerToken = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(ownerToken);

        var otherToken = await RegisterWithProfileAsync("Frontend");

        var response = await SendAsync(
            HttpMethod.Get,
            $"/api/projects/me/{project.Id}",
            otherToken);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CompleteStep_OtherUsersStep_ReturnsNotFound()
    {
        var ownerToken = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(ownerToken);

        var otherToken = await RegisterWithProfileAsync("Frontend");

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/projects/me/steps/{project.Steps[0].Id}/complete",
            otherToken);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        // Sahibinin adımı değişmemiştir.
        var unchanged = await GetProjectAsync(ownerToken);
        Assert.Equal(
            UserProjectStepStatus.Available,
            unchanged.Steps[0].Status);
    }

    [Fact]
    public async Task ProjectDetail_OwnProject_ReturnsSteps()
    {
        var token = await RegisterWithProfileAsync();
        var project = await GetProjectAsync(token);

        var response = await SendAsync(
            HttpMethod.Get,
            $"/api/projects/me/{project.Id}",
            token);

        response.EnsureSuccessStatusCode();

        var detail = await response
            .Content.ReadFromJsonAsync<UserProjectResponse>();

        Assert.Equal(project.Id, detail!.Id);
        Assert.Equal(project.TotalSteps, detail.Steps.Count);
    }
}
