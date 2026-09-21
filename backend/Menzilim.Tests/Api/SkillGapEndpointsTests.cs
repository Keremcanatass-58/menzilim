using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Services.Skills;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// GET /api/skills/gap/me ucunu gerçek HTTP akışıyla test eder.
/// </summary>
public sealed class SkillGapEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public SkillGapEndpointsTests()
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
            email = $"gap-{Guid.NewGuid():N}@menzilim.test",
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

    [Fact]
    public async Task SkillGap_RequiresAuthorization()
    {
        var response = await SendAsync(HttpMethod.Get, "/api/skills/gap/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SkillGap_WithoutOnboarding_ReturnsNotFound()
    {
        var token = await RegisterAsync();

        var response = await SendAsync(HttpMethod.Get, "/api/skills/gap/me", token);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task SkillGap_NewUser_AllSkillsNotStarted()
    {
        var token = await RegisterWithProfileAsync();

        var response = await SendAsync(HttpMethod.Get, "/api/skills/gap/me", token);
        response.EnsureSuccessStatusCode();

        var gap = await response.Content.ReadFromJsonAsync<SkillGapResponse>();

        Assert.Equal("Backend", gap!.SpecializationName);
        Assert.True(gap.TotalCount > 0);
        Assert.Equal(gap.TotalCount, gap.NotStartedCount);
        Assert.Equal(gap.TotalCount, gap.RemainingCount);
        Assert.Equal(0, gap.ReachedCount);

        Assert.All(gap.Items, item =>
        {
            Assert.Equal(SkillGapEngine.NotStarted, item.Status);
            Assert.Equal(SkillLevels.None, item.CurrentLevel);
            Assert.False(string.IsNullOrWhiteSpace(item.TargetLevel));
            Assert.True(item.TargetProgressPercent > 0);
        });
    }

    [Fact]
    public async Task SkillGap_UsesSeededTargetLevels()
    {
        var token = await RegisterWithProfileAsync();

        var response = await SendAsync(HttpMethod.Get, "/api/skills/gap/me", token);
        response.EnsureSuccessStatusCode();

        var gap = await response.Content.ReadFromJsonAsync<SkillGapResponse>();

        // Çekirdek beceri: Intermediate hedefi.
        Assert.Equal(
            SkillLevels.Intermediate,
            gap!.Items.Single(i => i.SkillName == "C#").TargetLevel);

        // Destek becerisi: Beginner hedefi.
        Assert.Equal(
            SkillLevels.Beginner,
            gap.Items.Single(i => i.SkillName == "Git ve Versiyon Kontrolü").TargetLevel);

        Assert.Equal(
            SkillSeeder.TargetLevelFor("Web Uygulama Güvenliği"),
            gap.Items.Single(i => i.SkillName == "Web Uygulama Güvenliği").TargetLevel);
    }

    [Fact]
    public async Task SkillGap_ReflectsCompletedContent()
    {
        var token = await RegisterWithProfileAsync();

        // C# becerisine bağlı içerik tamamlanır.
        Guid contentId;
        await using (var db = _factory.CreateDbContext())
        {
            contentId = await db.Contents
                .Where(c => c.Title == "A tour of the C# language")
                .Select(c => c.Id)
                .SingleAsync();
        }

        (await SendAsync(
            HttpMethod.Post,
            $"/api/content/{contentId}/complete",
            token)).EnsureSuccessStatusCode();

        var response = await SendAsync(HttpMethod.Get, "/api/skills/gap/me", token);
        response.EnsureSuccessStatusCode();

        var gap = await response.Content.ReadFromJsonAsync<SkillGapResponse>();
        var csharp = gap!.Items.Single(i => i.SkillName == "C#");

        Assert.True(csharp.ProgressPercent > 0);
        Assert.NotEqual(SkillGapEngine.NotStarted, csharp.Status);
        Assert.True(gap.RemainingCount < gap.TotalCount || csharp.Status != SkillGapEngine.Reached);
    }

    [Fact]
    public async Task SkillGap_OnlyCoversUsersOwnSpecialization()
    {
        var backendToken = await RegisterWithProfileAsync("Backend");
        var frontendToken = await RegisterWithProfileAsync("Frontend");

        var backend = await (await SendAsync(
            HttpMethod.Get, "/api/skills/gap/me", backendToken))
            .Content.ReadFromJsonAsync<SkillGapResponse>();

        var frontend = await (await SendAsync(
            HttpMethod.Get, "/api/skills/gap/me", frontendToken))
            .Content.ReadFromJsonAsync<SkillGapResponse>();

        Assert.Contains(backend!.Items, i => i.SkillName == "C#");
        Assert.DoesNotContain(backend.Items, i => i.SkillName == "React");

        Assert.Contains(frontend!.Items, i => i.SkillName == "React");
        Assert.DoesNotContain(frontend.Items, i => i.SkillName == "C#");
    }
}
