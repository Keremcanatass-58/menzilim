using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Services.News;
using Menzilim.Domain;
using Menzilim.Tests.DailyPlan;
using Xunit;

namespace Menzilim.Tests.News;

public class NewsServiceTests
{
    private static readonly Guid ProfessionId = Guid.NewGuid();
    private static readonly Guid SpecializationId = Guid.NewGuid();

    private static User UserWithProfile() =>
        new()
        {
            Id = Guid.NewGuid(),
            Profile = new UserProfile
            {
                ProfessionId = ProfessionId,
                SpecializationId = SpecializationId,
                Profession = new Profession { Name = "Yazılım Geliştirici" },
                Specialization = new Specialization { Name = "Backend" },
            },
        };

    private static NewsItem News(string title) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Summary = $"{title} özeti",
            SourceName = ".NET Blog",
            SourceUrl = $"https://example.com/{title}",
            PublishedAt = new DateTime(2025, 11, 11, 0, 0, 0, DateTimeKind.Utc),
            ImageUrl = null,
            IsActive = true,
        };

    [Fact]
    public async Task WithoutOnboardingProfile_ReturnsEmpty_WithoutQueryingNews()
    {
        var repo = new FakeNewsRepository();
        var service = new NewsService(new FakeUserRepository { User = new User() }, repo);

        var result = await service.GetForUserAsync(Guid.NewGuid());

        Assert.Empty(result);
        Assert.Empty(repo.Calls);
    }

    [Fact]
    public async Task UnknownUser_ReturnsEmpty()
    {
        var service = new NewsService(new FakeUserRepository { User = null }, new FakeNewsRepository());

        Assert.Empty(await service.GetForUserAsync(Guid.NewGuid()));
    }

    [Fact]
    public async Task UsesSpecializationNews_AndDoesNotFallBack_WhenAvailable()
    {
        var repo = new FakeNewsRepository
        {
            BySpecialization = { News(".NET 10") },
            ByProfession = { News("React 19") },
        };
        var service = new NewsService(new FakeUserRepository { User = UserWithProfile() }, repo);

        var result = await service.GetForUserAsync(Guid.NewGuid());

        Assert.Equal(new[] { ".NET 10" }, result.Select(n => n.Title));
        Assert.Equal(new[] { $"spec:{SpecializationId}:{NewsService.MaxItems}" }, repo.Calls);
    }

    [Fact]
    public async Task FallsBackToProfessionNews_WhenSpecializationHasNone()
    {
        var repo = new FakeNewsRepository { ByProfession = { News("React 19") } };
        var service = new NewsService(new FakeUserRepository { User = UserWithProfile() }, repo);

        var result = await service.GetForUserAsync(Guid.NewGuid());

        Assert.Equal(new[] { "React 19" }, result.Select(n => n.Title));
        Assert.Equal(
            new[]
            {
                $"spec:{SpecializationId}:{NewsService.MaxItems}",
                $"prof:{ProfessionId}:{NewsService.MaxItems}",
            },
            repo.Calls);
    }

    [Fact]
    public async Task ReturnsEmpty_WhenNeitherSpecializationNorProfessionHasNews()
    {
        var service = new NewsService(
            new FakeUserRepository { User = UserWithProfile() },
            new FakeNewsRepository());

        Assert.Empty(await service.GetForUserAsync(Guid.NewGuid()));
    }

    [Fact]
    public async Task MapsAllResponseFields_AndKeepsRepositoryOrder()
    {
        var first = News("Birinci");
        first.ImageUrl = "https://example.com/img.png";
        var second = News("İkinci");

        var repo = new FakeNewsRepository { BySpecialization = { first, second } };
        var service = new NewsService(new FakeUserRepository { User = UserWithProfile() }, repo);

        var result = await service.GetForUserAsync(Guid.NewGuid());

        Assert.Equal(new[] { first.Id, second.Id }, result.Select(n => n.Id));

        var mapped = result[0];
        Assert.Equal(first.Title, mapped.Title);
        Assert.Equal(first.Summary, mapped.Summary);
        Assert.Equal(first.SourceName, mapped.SourceName);
        Assert.Equal(first.SourceUrl, mapped.SourceUrl);
        Assert.Equal(first.PublishedAt, mapped.PublishedAt);
        Assert.Equal(first.ImageUrl, mapped.ImageUrl);
        Assert.Null(result[1].ImageUrl);
    }

    private sealed class FakeNewsRepository : INewsRepository
    {
        public List<NewsItem> BySpecialization { get; } = new();
        public List<NewsItem> ByProfession { get; } = new();
        public List<string> Calls { get; } = new();

        public Task<List<NewsItem>> GetActiveBySpecializationAsync(Guid specializationId, int take)
        {
            Calls.Add($"spec:{specializationId}:{take}");
            return Task.FromResult(BySpecialization.Take(take).ToList());
        }

        public Task<List<NewsItem>> GetActiveByProfessionAsync(Guid professionId, int take)
        {
            Calls.Add($"prof:{professionId}:{take}");
            return Task.FromResult(ByProfession.Take(take).ToList());
        }
    }
}
