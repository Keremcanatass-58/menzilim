using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Services.DailyPlan;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.DailyPlan;

public class DailyPlanServiceTests
{
    [Fact]
    public async Task GetTodayAsync_WhenPlanExists_ReusesItWithoutRegenerating()
    {
        var userId = Guid.NewGuid();
        var planRepo = new FakeDailyPlanRepository
        {
            Existing = ExistingPlan(userId, minutes: 42),
        };
        var service = BuildService(
            planRepo,
            new FakeUserRepository(),
            new FakeContentProgressRepository(),
            new FakeQuizRepository(),
            new FakeContentRepository());

        var response = await service.GetTodayAsync(userId);

        Assert.Equal(0, planRepo.AddCount); // yeni plan üretilmedi
        Assert.Equal("Var Olan Plan", response.Title);
        Assert.Equal(42, response.TotalMinutes);
    }

    [Fact]
    public async Task GetTodayAsync_WhenNoPlan_CreatesPersonalizedPlanAndPersistsOnce()
    {
        var userId = Guid.NewGuid();
        var planRepo = new FakeDailyPlanRepository { Existing = null };
        var userRepo = new FakeUserRepository
        {
            User = UserWith(minutes: 60, spec: "Backend"),
        };
        var service = BuildService(
            planRepo,
            userRepo,
            new FakeContentProgressRepository(),
            new FakeQuizRepository(),
            new FakeContentRepository());

        var response = await service.GetTodayAsync(userId);

        Assert.Equal(1, planRepo.AddCount); // tam olarak bir kez eklendi
        Assert.True(planRepo.SaveCount >= 1);
        Assert.Equal(3, response.Tasks.Count);
        Assert.Equal(60, response.TotalMinutes);
        Assert.Contains("Backend", response.Title);
    }

    [Fact]
    public async Task GetTodayAsync_PersonalizesTaskCountByDailyMinutes()
    {
        var shortPlan = await CreatePlanFor(minutes: 30);
        var longPlan = await CreatePlanFor(minutes: 90);

        Assert.Equal(2, shortPlan.Tasks.Count);
        Assert.Equal(30, shortPlan.Tasks.Sum(t => t.EstimatedMinutes));

        Assert.Equal(4, longPlan.Tasks.Count);
        Assert.Equal(90, longPlan.Tasks.Sum(t => t.EstimatedMinutes));
    }

    [Fact]
    public async Task GetTodayAsync_LinksLearnTaskToSuitableContent()
    {
        var content = new Content
        {
            Id = Guid.NewGuid(),
            Title = "Backend 101",
            PublishedAt = new DateTime(2026, 1, 1),
            IsActive = true,
        };
        var contentRepo = new FakeContentRepository();
        contentRepo.ProfessionContent.Add(content);

        var service = BuildService(
            new FakeDailyPlanRepository { Existing = null },
            new FakeUserRepository { User = UserWith(60) },
            new FakeContentProgressRepository(),
            new FakeQuizRepository(),
            contentRepo);

        var response = await service.GetTodayAsync(Guid.NewGuid());

        var learn = response.Tasks.Single(t => t.TaskType == "Learn");
        Assert.Equal(content.Id, learn.ContentId);

        // Learn dışındaki görevlerde ContentId null kalır (geriye uyumlu).
        Assert.All(
            response.Tasks.Where(t => t.TaskType != "Learn"),
            t => Assert.Null(t.ContentId));
    }

    [Fact]
    public async Task GetTodayAsync_WhenNoContent_UsesSafeFallback()
    {
        var service = BuildService(
            new FakeDailyPlanRepository { Existing = null },
            new FakeUserRepository { User = UserWith(60) },
            new FakeContentProgressRepository(),
            new FakeQuizRepository(),
            new FakeContentRepository()); // içerik yok

        var response = await service.GetTodayAsync(Guid.NewGuid());

        var learn = response.Tasks.Single(t => t.TaskType == "Learn");
        Assert.Null(learn.ContentId);       // fallback: içerik bağlanmadı
        Assert.Equal(3, response.Tasks.Count); // plan yine de oluştu
    }

    // -- helpers -------------------------------------------------------------

    private static async Task<Menzilim.Application.DTOs.DailyPlan.DailyPlanResponse>
        CreatePlanFor(int minutes)
    {
        var userId = Guid.NewGuid();
        var service = BuildService(
            new FakeDailyPlanRepository { Existing = null },
            new FakeUserRepository { User = UserWith(minutes) },
            new FakeContentProgressRepository(),
            new FakeQuizRepository(),
            new FakeContentRepository());

        return await service.GetTodayAsync(userId);
    }

    private static DailyPlanService BuildService(
        IDailyPlanRepository planRepo,
        IUserRepository userRepo,
        IUserContentProgressRepository progressRepo,
        IQuizRepository quizRepo,
        IContentRepository contentRepo) =>
        new(planRepo, userRepo, progressRepo, quizRepo, contentRepo, new FakeSkillRepository());

    private static User UserWith(
        int minutes,
        string spec = "Backend",
        string prof = "Yazılım Geliştirici",
        string level = "Beginner",
        string goal = "Backend Developer") =>
        new()
        {
            Id = Guid.NewGuid(),
            Profile = new UserProfile
            {
                ExperienceLevel = level,
                CareerGoal = goal,
                DailyLearningMinutes = minutes,
                Profession = new Profession { Name = prof },
                Specialization = new Specialization { Name = spec },
            },
        };

    private static Menzilim.Domain.DailyPlan ExistingPlan(Guid userId, int minutes)
    {
        var plan = new Menzilim.Domain.DailyPlan
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Date = DateTime.UtcNow.Date,
            Title = "Var Olan Plan",
            CreatedAt = DateTime.UtcNow,
        };

        plan.Tasks.Add(new DailyTask
        {
            Id = Guid.NewGuid(),
            DailyPlanId = plan.Id,
            Title = "Mevcut Görev",
            TaskType = "Learn",
            EstimatedMinutes = minutes,
            IsCompleted = false,
        });

        return plan;
    }
}

// ---- in-memory fakes -------------------------------------------------------

internal sealed class FakeDailyPlanRepository : IDailyPlanRepository
{
    public Task<List<DailyTask>> GetTasksByProjectStepAsync(Guid userProjectStepId) =>
        Task.FromResult(new List<DailyTask>());

    public Menzilim.Domain.DailyPlan? Existing;
    public Menzilim.Domain.DailyPlan? Added;
    public int AddCount;
    public int SaveCount;

    public Task<Menzilim.Domain.DailyPlan?> GetByUserAndDateAsync(Guid userId, DateTime date) =>
        Task.FromResult(Existing);

    public Task<DailyTask?> GetTaskByIdAsync(Guid taskId) =>
        Task.FromResult<DailyTask?>(null);

    public Task AddAsync(Menzilim.Domain.DailyPlan dailyPlan)
    {
        AddCount++;
        Added = dailyPlan;
        return Task.CompletedTask;
    }

    public Task<List<Menzilim.Domain.DailyPlan>> GetAllByUserAsync(Guid userId) =>
        Task.FromResult(new List<Menzilim.Domain.DailyPlan>());

    public Task SaveChangesAsync()
    {
        SaveCount++;
        return Task.CompletedTask;
    }
}

internal sealed class FakeUserRepository : IUserRepository
{
    public User? User;

    public Task<User?> GetByEmailAsync(string email) => Task.FromResult<User?>(null);
    public Task<User?> GetByIdAsync(Guid id) => Task.FromResult<User?>(null);
    public Task<User?> GetByIdWithProfileDetailsAsync(Guid id) => Task.FromResult(User);
    public Task AddAsync(User user) => Task.CompletedTask;
    public Task AddProfileAsync(UserProfile profile) => Task.CompletedTask;
    public Task SaveChangesAsync() => Task.CompletedTask;
}

internal sealed class FakeContentProgressRepository : IUserContentProgressRepository
{
    public List<UserContentProgress> Items = new();

    public Task<UserContentProgress?> GetAsync(Guid userId, Guid contentId) =>
        Task.FromResult<UserContentProgress?>(null);

    public Task<List<UserContentProgress>> GetByUserAsync(Guid userId) =>
        Task.FromResult(Items);

    public Task AddAsync(UserContentProgress progress) => Task.CompletedTask;
    public Task SaveChangesAsync() => Task.CompletedTask;
}

internal sealed class FakeQuizRepository : IQuizRepository
{
    public int AttemptCount = 0;

    public Task<List<Menzilim.Domain.Quiz>> GetAllActiveAsync() =>
        Task.FromResult(new List<Menzilim.Domain.Quiz>());

    public Task<Menzilim.Domain.Quiz?> GetByIdWithQuestionsAsync(Guid id) =>
        Task.FromResult<Menzilim.Domain.Quiz?>(null);

    public Task<Menzilim.Domain.Quiz?> GetFirstActiveWithQuestionsAsync() =>
        Task.FromResult<Menzilim.Domain.Quiz?>(null);

    public Task AddAttemptAsync(QuizAttempt attempt) => Task.CompletedTask;

    public Task<int> GetAttemptCountByUserAsync(Guid userId) =>
        Task.FromResult(AttemptCount);

    public Task<List<QuizAttempt>> GetByUserAsync(Guid userId) =>
        Task.FromResult(new List<QuizAttempt>());

    public Task SaveChangesAsync() => Task.CompletedTask;
}

// Skill verisi olmayan kullanıcı: mevcut (skill öncesi) seçim davranışı korunur.
internal sealed class FakeSkillRepository : ISkillRepository
{
    public Task<List<SpecializationSkill>> GetSpecializationSkillsAsync(Guid specializationId) =>
        Task.FromResult(new List<SpecializationSkill>());

    public Task<bool> SpecializationExistsAsync(Guid specializationId) =>
        Task.FromResult(false);

    public Task<List<Skill>> GetActiveBySpecializationAsync(Guid specializationId) =>
        Task.FromResult(new List<Skill>());

    public Task<List<ContentSkill>> GetActiveContentLinksAsync(IReadOnlyCollection<Guid> skillIds) =>
        Task.FromResult(new List<ContentSkill>());

    public Task<List<Menzilim.Domain.Quiz>> GetActiveQuizzesAsync(IReadOnlyCollection<Guid> skillIds) =>
        Task.FromResult(new List<Menzilim.Domain.Quiz>());

    public Task<List<QuizAttempt>> GetUserQuizAttemptsAsync(Guid userId, IReadOnlyCollection<Guid> quizIds) =>
        Task.FromResult(new List<QuizAttempt>());
}

internal sealed class FakeContentRepository : IContentRepository
{
    public List<Content> ProfessionContent = new();

    public Task<List<Content>> GetActiveAsync() =>
        Task.FromResult(ProfessionContent);

    public Task<Content?> GetByIdAsync(Guid contentId) =>
        Task.FromResult(ProfessionContent.FirstOrDefault(c => c.Id == contentId));

    public Task<List<Content>> GetByProfessionAsync(Guid professionId) =>
        Task.FromResult(ProfessionContent);

    public Task AddAsync(Content content) => Task.CompletedTask;
    public Task SaveChangesAsync() => Task.CompletedTask;
}
