using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.News;
using Menzilim.Application.Services.News;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// GET /api/news/me ucunu gerçek HTTP akışıyla (JWT, register, onboarding ve
/// uygulama açılışındaki seed) test eder.
/// </summary>
public sealed class NewsEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public NewsEndpointsTests()
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
            email = $"news-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });
        register.EnsureSuccessStatusCode();
        return (await register.Content.ReadFromJsonAsync<AuthResponse>())!.Token;
    }

    private async Task<string> RegisterWithProfileAsync(string specializationName)
    {
        var token = await RegisterAsync();

        Guid professionId, specializationId;
        await using (var db = _factory.CreateDbContext())
        {
            var spec = await db.Specializations.SingleAsync(s => s.Name == specializationName);
            professionId = spec.ProfessionId;
            specializationId = spec.Id;

            // Bu testler haber kişiselleştirmesini her meslek için ölçer;
            // release'e hazırlık kapısı (IsAvailable) kapsam dışıdır.
            var profession = await db.Professions.SingleAsync(p => p.Id == professionId);
            profession.IsAvailable = true;
            await db.SaveChangesAsync();
        }

        (await SendAsync("/api/onboarding", token, HttpMethod.Post, new
        {
            professionId,
            specializationId,
            experienceLevel = "Beginner",
            careerGoal = "Gelişmek",
            dailyLearningMinutes = 60,
        })).EnsureSuccessStatusCode();

        return token;
    }

    private async Task<HttpResponseMessage> SendAsync(
        string url, string? token, HttpMethod? method = null, object? body = null)
    {
        using var request = new HttpRequestMessage(method ?? HttpMethod.Get, url);
        if (token is not null)
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null)
            request.Content = JsonContent.Create(body);
        return await _client.SendAsync(request);
    }

    private async Task<List<NewsItemResponse>> GetMyNewsAsync(string token)
    {
        var response = await SendAsync("/api/news/me", token);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<List<NewsItemResponse>>())!;
    }

    // Seed kataloğuna göre uzmanlığın skill'lerine bağlı haberler.
    private static List<NewsSeeder.NewsDefinition> SeededNewsFor(string specialization)
    {
        var skills = SkillSeeder.SpecializationSkills[specialization].ToHashSet();
        return NewsSeeder.News.Where(n => n.SkillNames.Any(skills.Contains)).ToList();
    }

    [Fact]
    public async Task WithoutToken_Returns401()
    {
        var response = await _client.GetAsync("/api/news/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task WithoutOnboarding_Returns200_WithEmptyList()
    {
        var token = await RegisterAsync();

        var news = await GetMyNewsAsync(token);

        Assert.Empty(news);
    }

    [Theory]
    [InlineData("Frontend", "Node.js 25 yayınlandı")]
    [InlineData("Backend", ".NET 10 yayınlandı: yeni LTS sürümü")]
    [InlineData("Full Stack", "React 19.2 yayınlandı")]
    [InlineData("Mobile", "Flutter 3.32 yayınlandı")]
    public async Task ReturnsSpecializationNews_SortedAndLimited(
        string specialization,
        string expectedTitle)
    {
        var token = await RegisterWithProfileAsync(specialization);

        var news = await GetMyNewsAsync(token);

        var expected = SeededNewsFor(specialization);
        var expectedUrls = expected.Select(n => n.SourceUrl).ToHashSet();

        Assert.Equal(Math.Min(NewsService.MaxItems, expected.Count), news.Count);
        Assert.All(news, n => Assert.Contains(n.SourceUrl, expectedUrls));
        Assert.Contains(news, n => n.Title == expectedTitle);

        // PublishedAt azalan.
        Assert.Equal(
            news.OrderByDescending(n => n.PublishedAt).Select(n => n.Id),
            news.Select(n => n.Id));

        // Sınır aşılırsa en yeniler kalır.
        var oldestReturned = news.Min(n => n.PublishedAt);
        Assert.All(
            expected.Where(e => !news.Any(n => n.SourceUrl == e.SourceUrl)),
            missing => Assert.True(missing.PublishedAt <= oldestReturned));
    }

    [Fact]
    public async Task Backend_DoesNotReceiveMobileOrFrontendOnlyNews()
    {
        var token = await RegisterWithProfileAsync("Backend");

        var titles = (await GetMyNewsAsync(token)).Select(n => n.Title).ToList();

        Assert.DoesNotContain("Flutter 3.32 yayınlandı", titles);
        Assert.DoesNotContain("React 19.2 yayınlandı", titles);
        Assert.Contains("EF Core 10 yayınlandı", titles);
    }

    [Fact]
    public async Task FullStack_IsCappedAtTen()
    {
        Assert.True(SeededNewsFor("Full Stack").Count > NewsService.MaxItems);

        var token = await RegisterWithProfileAsync("Full Stack");

        Assert.Equal(NewsService.MaxItems, (await GetMyNewsAsync(token)).Count);
    }

    [Fact]
    public async Task FallsBackToProfessionNews_WhenSpecializationHasNone()
    {
        var token = await RegisterWithProfileAsync("Mobile");

        // Mobile'a ait haberler (Flutter/Dart) yayından kalkmış olsun.
        await using (var db = _factory.CreateDbContext())
        {
            var mobileUrls = SeededNewsFor("Mobile").Select(n => n.SourceUrl).ToList();
            await db.NewsItems
                .Where(n => mobileUrls.Contains(n.SourceUrl))
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsActive, false));
        }

        var news = await GetMyNewsAsync(token);

        // Yazılım Geliştirici mesleğinin diğer uzmanlıklarının haberleri.
        Assert.Equal(NewsService.MaxItems, news.Count);
        Assert.DoesNotContain(news, n => n.Title.Contains("Flutter") || n.Title.Contains("Dart"));
    }

    [Fact]
    public async Task ProfessionWithoutAnyNews_ReturnsEmpty()
    {
        var token = await RegisterWithProfileAsync("SOC");

        Assert.Empty(await GetMyNewsAsync(token));
    }

    [Fact]
    public async Task InactiveNews_IsNotReturned()
    {
        var token = await RegisterWithProfileAsync("Backend");
        var target = SeededNewsFor("Backend")[0];

        await using (var db = _factory.CreateDbContext())
        {
            await db.NewsItems
                .Where(n => n.SourceUrl == target.SourceUrl)
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsActive, false));
        }

        var news = await GetMyNewsAsync(token);

        Assert.DoesNotContain(news, n => n.SourceUrl == target.SourceUrl);
        Assert.Equal(SeededNewsFor("Backend").Count - 1, news.Count);
    }

    [Fact]
    public async Task Response_HasContractFields()
    {
        var token = await RegisterWithProfileAsync("Backend");

        var response = await SendAsync("/api/news/me", token);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var first = json.EnumerateArray().First();

        foreach (var field in new[] { "id", "title", "summary", "sourceName", "sourceUrl", "publishedAt", "imageUrl" })
            Assert.True(first.TryGetProperty(field, out _), $"eksik alan: {field}");

        Assert.Equal(JsonValueKind.Null, first.GetProperty("imageUrl").ValueKind);
        Assert.StartsWith("https://", first.GetProperty("sourceUrl").GetString());
    }

    [Fact]
    public async Task SameRequest_ReturnsSameOrder()
    {
        var token = await RegisterWithProfileAsync("Full Stack");

        var first = await GetMyNewsAsync(token);
        var second = await GetMyNewsAsync(token);

        Assert.Equal(first.Select(n => n.Id), second.Select(n => n.Id));
    }
}
