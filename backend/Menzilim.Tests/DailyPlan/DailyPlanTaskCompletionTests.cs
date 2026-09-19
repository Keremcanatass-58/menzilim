using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.DailyPlan;
using Menzilim.Application.Services.DailyPlan;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Menzilim.Infrastructure.Repositories;
using Xunit;

namespace Menzilim.Tests.DailyPlan;

/// <summary>
/// Görev tamamlama ve görev sıralamasını gerçek repository'lerle (SQLite
/// in-memory) test eder. Her kontrol yeni bir DbContext ile yapılır; böylece
/// yalnızca veritabanından yüklenen veri değerlendirilir.
/// </summary>
public sealed class DailyPlanTaskCompletionTests : IDisposable
{
    private readonly SqliteConnection _connection;

    public DailyPlanTaskCompletionTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        using var db = CreateContext();
        db.Database.EnsureCreated();
        DatabaseSeeder.SeedAsync(db).GetAwaiter().GetResult();
    }

    public void Dispose() => _connection.Dispose();

    private MenzilimDbContext CreateContext() =>
        new(new DbContextOptionsBuilder<MenzilimDbContext>()
            .UseSqlite(_connection)
            .Options);

    private static DailyPlanService CreateService(MenzilimDbContext db) =>
        new(
            new DailyPlanRepository(db),
            new UserRepository(db),
            new UserContentProgressRepository(db),
            new QuizRepository(db),
            new ContentRepository(db),
            new SkillRepository(db));

    private async Task<DailyPlanResponse> GetTodayAsync(Guid userId)
    {
        await using var db = CreateContext();
        return await CreateService(db).GetTodayAsync(userId);
    }

    private async Task<DailyPlanResponse> CompleteAsync(Guid userId, Guid taskId)
    {
        await using var db = CreateContext();
        return await CreateService(db).CompleteTaskAsync(userId, taskId);
    }

    private async Task<(bool PlanCompleted, List<DailyTask> Tasks)> ReadFromDbAsync(Guid planId)
    {
        await using var db = CreateContext();
        var plan = await db.DailyPlans.AsNoTracking().SingleAsync(p => p.Id == planId);
        var tasks = await db.DailyTasks.AsNoTracking()
            .Where(t => t.DailyPlanId == planId)
            .ToListAsync();
        return (plan.IsCompleted, tasks);
    }

    private async Task<Guid> CreateUserAsync(int minutes)
    {
        await using var db = CreateContext();
        var spec = await db.Specializations.SingleAsync(s => s.Name == "Backend");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = $"{Guid.NewGuid():N}@menzilim.test",
            FirstName = "Test",
            LastName = "Kullanıcı",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };
        db.Users.Add(user);
        db.UserProfiles.Add(new UserProfile
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            ProfessionId = spec.ProfessionId,
            SpecializationId = spec.Id,
            ExperienceLevel = "Beginner",
            CareerGoal = "Backend geliştirici olmak",
            DailyLearningMinutes = minutes,
            UpdatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        return user.Id;
    }

    private static Guid TaskId(DailyPlanResponse plan, string type) =>
        plan.Tasks.Single(t => t.TaskType == type).Id;

    [Fact]
    public async Task CompletingOneOfThreeTasks_KeepsPlanOpen_AndReturnsAllTasks()
    {
        var userId = await CreateUserAsync(60);
        var plan = await GetTodayAsync(userId);
        Assert.Equal(3, plan.Tasks.Count);

        var response = await CompleteAsync(userId, TaskId(plan, "Learn"));

        // Yanıt: planın TÜM görevleri, yalnızca Learn tamamlanmış.
        Assert.False(response.IsCompleted);
        Assert.Equal(3, response.Tasks.Count);
        Assert.True(response.Tasks.Single(t => t.TaskType == "Learn").IsCompleted);
        Assert.False(response.Tasks.Single(t => t.TaskType == "Practice").IsCompleted);
        Assert.False(response.Tasks.Single(t => t.TaskType == "Quiz").IsCompleted);
        Assert.Equal(60, response.TotalMinutes);
        Assert.Equal(response.Tasks.Single(t => t.TaskType == "Learn").EstimatedMinutes,
            response.CompletedMinutes);

        // Veritabanı: plan hâlâ açık.
        var (planCompleted, tasks) = await ReadFromDbAsync(plan.Id);
        Assert.False(planCompleted);
        Assert.Equal(1, tasks.Count(t => t.IsCompleted));
    }

    [Fact]
    public async Task CompletingAllTasks_MarksPlanCompleted()
    {
        var userId = await CreateUserAsync(60);
        var plan = await GetTodayAsync(userId);

        var afterLearn = await CompleteAsync(userId, TaskId(plan, "Learn"));
        var afterPractice = await CompleteAsync(userId, TaskId(plan, "Practice"));
        var afterQuiz = await CompleteAsync(userId, TaskId(plan, "Quiz"));

        Assert.False(afterLearn.IsCompleted);
        Assert.False(afterPractice.IsCompleted);
        Assert.True(afterQuiz.IsCompleted);
        Assert.All(afterQuiz.Tasks, t => Assert.True(t.IsCompleted));
        Assert.Equal(60, afterQuiz.CompletedMinutes);

        var (planCompleted, _) = await ReadFromDbAsync(plan.Id);
        Assert.True(planCompleted);
    }

    [Fact]
    public async Task ReloadedPlanAfterCompletion_ContainsAllTasks()
    {
        var userId = await CreateUserAsync(90);
        var plan = await GetTodayAsync(userId);

        await CompleteAsync(userId, TaskId(plan, "Practice"));
        var reloaded = await GetTodayAsync(userId);

        Assert.Equal(plan.Id, reloaded.Id);
        Assert.Equal(4, reloaded.Tasks.Count);
        Assert.Equal(
            plan.Tasks.Select(t => t.Id).OrderBy(id => id),
            reloaded.Tasks.Select(t => t.Id).OrderBy(id => id));
        Assert.Equal(new[] { "Practice" },
            reloaded.Tasks.Where(t => t.IsCompleted).Select(t => t.TaskType));
        Assert.False(reloaded.IsCompleted);
    }

    [Fact]
    public async Task Tasks_AreReturnedInLearnPracticeQuizReviewOrder_EvenIfStoredOtherwise()
    {
        var userId = await CreateUserAsync(90);
        var planId = Guid.NewGuid();

        // Görevleri ters sırada, ayrı ayrı kaydet (veritabanı sırası ters olsun).
        await using (var db = CreateContext())
        {
            db.DailyPlans.Add(new Menzilim.Domain.DailyPlan
            {
                Id = planId,
                UserId = userId,
                Date = DateTime.UtcNow.Date,
                Title = "Ters Sıralı Plan",
                CreatedAt = DateTime.UtcNow,
            });
            await db.SaveChangesAsync();
        }

        foreach (var type in new[] { "Review", "Quiz", "Practice", "Learn" })
        {
            await using var db = CreateContext();
            db.DailyTasks.Add(new DailyTask
            {
                Id = Guid.NewGuid(),
                DailyPlanId = planId,
                Title = $"{type} görevi",
                TaskType = type,
                EstimatedMinutes = 10,
            });
            await db.SaveChangesAsync();
        }

        var expected = new[] { "Learn", "Practice", "Quiz", "Review" };

        var today = await GetTodayAsync(userId);
        Assert.Equal(planId, today.Id); // mevcut plan kullanıldı
        Assert.Equal(expected, today.Tasks.Select(t => t.TaskType));

        var afterComplete = await CompleteAsync(userId, TaskId(today, "Quiz"));
        Assert.Equal(expected, afterComplete.Tasks.Select(t => t.TaskType));
    }

    [Fact]
    public async Task UnknownTaskTypes_AreOrderedLast_Deterministically()
    {
        var userId = await CreateUserAsync(60);
        var planId = Guid.NewGuid();

        await using (var db = CreateContext())
        {
            var plan = new Menzilim.Domain.DailyPlan
            {
                Id = planId,
                UserId = userId,
                Date = DateTime.UtcNow.Date,
                Title = "Plan",
                CreatedAt = DateTime.UtcNow,
            };
            foreach (var (type, title) in new[] { ("Bonus", "B"), ("Quiz", "Q"), ("Bonus", "A"), ("learn", "L") })
            {
                plan.Tasks.Add(new DailyTask
                {
                    Id = Guid.NewGuid(),
                    DailyPlanId = planId,
                    Title = title,
                    TaskType = type,
                    EstimatedMinutes = 5,
                });
            }
            db.DailyPlans.Add(plan);
            await db.SaveChangesAsync();
        }

        var today = await GetTodayAsync(userId);

        Assert.Equal(new[] { "L", "Q", "A", "B" }, today.Tasks.Select(t => t.Title));
    }

    [Fact]
    public async Task CompletingAnotherUsersTask_IsRejected_AndNothingChanges()
    {
        var owner = await CreateUserAsync(60);
        var intruder = await CreateUserAsync(60);
        var plan = await GetTodayAsync(owner);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => CompleteAsync(intruder, TaskId(plan, "Learn")));

        var (planCompleted, tasks) = await ReadFromDbAsync(plan.Id);
        Assert.False(planCompleted);
        Assert.All(tasks, t => Assert.False(t.IsCompleted));
    }

    [Fact]
    public async Task CompletingUnknownTask_ThrowsNotFound()
    {
        var userId = await CreateUserAsync(60);

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(
            () => CompleteAsync(userId, Guid.NewGuid()));

        Assert.Equal("Görev bulunamadı.", ex.Message);
    }

    [Fact]
    public async Task CompletingAlreadyCompletedTask_IsIdempotent()
    {
        var userId = await CreateUserAsync(60);
        var plan = await GetTodayAsync(userId);
        var learnId = TaskId(plan, "Learn");

        var first = await CompleteAsync(userId, learnId);
        var second = await CompleteAsync(userId, learnId);

        var firstLearn = first.Tasks.Single(t => t.Id == learnId);
        var secondLearn = second.Tasks.Single(t => t.Id == learnId);

        Assert.True(secondLearn.IsCompleted);
        Assert.Equal(firstLearn.CompletedAt, secondLearn.CompletedAt); // ilk zaman korunur
        Assert.False(second.IsCompleted);
        Assert.Equal(3, second.Tasks.Count);
        Assert.Equal(first.CompletedMinutes, second.CompletedMinutes);
    }
}
