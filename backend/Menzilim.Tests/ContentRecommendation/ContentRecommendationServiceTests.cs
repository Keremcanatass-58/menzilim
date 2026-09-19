using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Services.Content;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.ContentRecommendation;

public class ContentRecommendationServiceTests
{
    private static readonly Guid ProfessionId = Guid.NewGuid();

    private static Menzilim.Domain.Content MakeContent(string title) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Url = "https://example.com",
            PublishedAt = new DateTime(2026, 1, 1),
            IsActive = true,
        };

    private static User UserWithProfile(Guid userId) =>
        new()
        {
            Id = userId,
            Profile = new UserProfile
            {
                UserId = userId,
                ProfessionId = ProfessionId,
                ExperienceLevel = "Beginner",
                CareerGoal = "Backend geliştirici olmak",
                Profession = new Profession { Id = ProfessionId, Name = "Yazılım Geliştirici" },
                Specialization = new Specialization { Name = "Backend" },
            },
        };

    [Fact]
    public async Task GetForUserAsync_Throws_WhenUserNotFound()
    {
        var service = new ContentRecommendationService(
            new FakeUserRepository(null),
            new FakeContentRepository(),
            new FakeProgressRepository());

        var ex = await Assert.ThrowsAsync<KeyNotFoundException>(
            () => service.GetForUserAsync(Guid.NewGuid()));

        Assert.Equal("Kullanıcı bulunamadı.", ex.Message);
    }

    [Fact]
    public async Task GetForUserAsync_Throws_WhenProfileMissing()
    {
        var userId = Guid.NewGuid();
        var service = new ContentRecommendationService(
            new FakeUserRepository(new User { Id = userId }),
            new FakeContentRepository(),
            new FakeProgressRepository());

        var ex = await Assert.ThrowsAsync<KeyNotFoundException>(
            () => service.GetForUserAsync(userId));

        Assert.Equal("Kullanıcı profili bulunamadı.", ex.Message);
    }

    [Fact]
    public async Task GetForUserAsync_UsesProfileDetails_AndSkipsFullContentLoad()
    {
        var userId = Guid.NewGuid();
        var own = MakeContent("Genel Konu");
        var contentRepo = new FakeContentRepository { ByProfession = { own } };

        var service = new ContentRecommendationService(
            new FakeUserRepository(UserWithProfile(userId)),
            contentRepo,
            new FakeProgressRepository());

        var result = await service.GetForUserAsync(userId);

        Assert.Single(result);
        Assert.Equal(own.Id, result[0].ContentId);
        Assert.Contains("Yazılım Geliştirici", result[0].RecommendationReason);
        Assert.Contains("Backend geliştirici olmak", result[0].RecommendationReason);
        Assert.Equal(ProfessionId, contentRepo.RequestedProfessionId);
        Assert.Equal(0, contentRepo.GetActiveCallCount);
    }

    [Fact]
    public async Task GetForUserAsync_LoadsActiveContent_OnlyForInProgressOutsideProfession()
    {
        var userId = Guid.NewGuid();
        var own = MakeContent("Genel Konu");
        var other = MakeContent("Başka Meslek Konusu");
        var contentRepo = new FakeContentRepository
        {
            ByProfession = { own },
            Active = { own, other },
        };
        var progressRepo = new FakeProgressRepository
        {
            Items =
            {
                new UserContentProgress { UserId = userId, ContentId = other.Id, IsCompleted = false },
            },
        };

        var service = new ContentRecommendationService(
            new FakeUserRepository(UserWithProfile(userId)),
            contentRepo,
            progressRepo);

        var result = await service.GetForUserAsync(userId);

        Assert.Equal(1, contentRepo.GetActiveCallCount);
        Assert.Equal(new[] { other.Id, own.Id }, result.Select(r => r.ContentId));
    }

    private sealed class FakeUserRepository : IUserRepository
    {
        private readonly User? _user;

        public FakeUserRepository(User? user) => _user = user;

        public Task<User?> GetByIdWithProfileDetailsAsync(Guid id) =>
            Task.FromResult(_user?.Id == id ? _user : null);

        public Task<User?> GetByEmailAsync(string email) => throw new NotSupportedException();
        public Task<User?> GetByIdAsync(Guid id) => throw new NotSupportedException();
        public Task AddAsync(User user) => throw new NotSupportedException();
        public Task AddProfileAsync(UserProfile profile) => throw new NotSupportedException();
        public Task SaveChangesAsync() => throw new NotSupportedException();
    }

    private sealed class FakeContentRepository : IContentRepository
    {
        public List<Menzilim.Domain.Content> ByProfession { get; } = new();
        public List<Menzilim.Domain.Content> Active { get; } = new();
        public Guid? RequestedProfessionId { get; private set; }
        public int GetActiveCallCount { get; private set; }

        public Task<List<Menzilim.Domain.Content>> GetByProfessionAsync(Guid professionId)
        {
            RequestedProfessionId = professionId;
            return Task.FromResult(ByProfession.ToList());
        }

        public Task<List<Menzilim.Domain.Content>> GetActiveAsync()
        {
            GetActiveCallCount++;
            return Task.FromResult(Active.ToList());
        }

        public Task<Menzilim.Domain.Content?> GetByIdAsync(Guid contentId) => throw new NotSupportedException();
        public Task AddAsync(Menzilim.Domain.Content content) => throw new NotSupportedException();
        public Task SaveChangesAsync() => throw new NotSupportedException();
    }

    private sealed class FakeProgressRepository : IUserContentProgressRepository
    {
        public List<UserContentProgress> Items { get; } = new();

        public Task<List<UserContentProgress>> GetByUserAsync(Guid userId) =>
            Task.FromResult(Items.Where(p => p.UserId == userId).ToList());

        public Task<UserContentProgress?> GetAsync(Guid userId, Guid contentId) => throw new NotSupportedException();
        public Task AddAsync(UserContentProgress progress) => throw new NotSupportedException();
        public Task SaveChangesAsync() => throw new NotSupportedException();
    }
}
