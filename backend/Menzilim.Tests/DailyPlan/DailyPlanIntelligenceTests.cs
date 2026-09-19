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
/// Günlük planı gerçek repository'ler, gerçek seed (uzmanlık/skill kataloğu)
/// ve SkillProgressEngine ile SQLite in-memory üzerinde uçtan uca test eder.
/// </summary>
public sealed class DailyPlanIntelligenceTests : IDisposable
{
    private readonly SqliteConnection _connection;

    public DailyPlanIntelligenceTests()
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

    private async Task<DailyPlanResponse> GetTodayAsync(Guid userId)
    {
        await using var db = CreateContext();

        var service = new DailyPlanService(
            new DailyPlanRepository(db),
            new UserRepository(db),
            new UserContentProgressRepository(db),
            new QuizRepository(db),
            new ContentRepository(db),
            new SkillRepository(db));

        return await service.GetTodayAsync(userId);
    }

    private async Task<Guid> CreateUserAsync(int minutes, string specialization = "Backend")
    {
        await using var db = CreateContext();
        var spec = await db.Specializations.SingleAsync(s => s.Name == specialization);

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

    /// <summary>İçeriği bir mesleğe ve verilen skill'lere bağlar.</summary>
    private async Task<Guid> AddContentAsync(
        string title,
        int day,
        string profession = "Yazılım Geliştirici",
        params string[] skillNames)
    {
        await using var db = CreateContext();
        var professionId = (await db.Professions.SingleAsync(p => p.Name == profession)).Id;

        var content = new Content
        {
            Id = Guid.NewGuid(),
            Title = title,
            Url = "https://example.com",
            Source = "Test",
            Level = "Beginner",
            PublishedAt = new DateTime(2026, 1, day),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };
        db.Contents.Add(content);
        db.ContentProfessions.Add(new ContentProfession
        {
            Id = Guid.NewGuid(),
            ContentId = content.Id,
            ProfessionId = professionId,
        });

        foreach (var name in skillNames)
        {
            var skill = await db.Skills.SingleAsync(s => s.Name == name);
            db.ContentSkills.Add(new ContentSkill
            {
                Id = Guid.NewGuid(),
                ContentId = content.Id,
                SkillId = skill.Id,
            });
        }

        await db.SaveChangesAsync();
        return content.Id;
    }

    private async Task AddProgressAsync(Guid userId, Guid contentId, bool completed)
    {
        await using var db = CreateContext();
        db.UserContentProgresses.Add(new UserContentProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ContentId = contentId,
            StartedAt = new DateTime(2026, 9, 1),
            IsCompleted = completed,
            CompletedAt = completed ? new DateTime(2026, 9, 2) : null,
        });
        await db.SaveChangesAsync();
    }

    private static DailyTaskResponse TaskOf(DailyPlanResponse plan, string type) =>
        plan.Tasks.Single(t => t.TaskType == type);

    [Theory]
    [InlineData(30, new[] { "Learn", "Quiz" })]
    [InlineData(60, new[] { "Learn", "Practice", "Quiz" })]
    [InlineData(90, new[] { "Learn", "Practice", "Quiz", "Review" })]
    public async Task PlanDuration_MatchesDailyMinutes_WithExistingSlotRules(
        int minutes,
        string[] expectedTypes)
    {
        await AddContentAsync("C# Temelleri", 1, skillNames: "C#");
        await AddContentAsync("SQL Sorguları", 2, skillNames: "SQL");
        var userId = await CreateUserAsync(minutes);

        var plan = await GetTodayAsync(userId);

        Assert.Equal(expectedTypes, plan.Tasks.Select(t => t.TaskType));
        Assert.Equal(minutes, plan.Tasks.Sum(t => t.EstimatedMinutes));
        Assert.Equal(minutes, plan.TotalMinutes);
    }

    [Fact]
    public async Task LowProgressSkillContent_IsChosenBeforeProgressedSkill_AndTasksLinkCorrectly()
    {
        var userId = await CreateUserAsync(60);

        // ASP.NET Core: 2 içerikten 1'i tamamlandı → ilerleme > 0.
        var aspDone = await AddContentAsync("ASP.NET Core Giriş", 1, skillNames: "ASP.NET Core");
        var aspNext = await AddContentAsync("ASP.NET Core İleri", 30, skillNames: "ASP.NET Core");
        await AddProgressAsync(userId, aspDone, completed: true);

        // %0 skill'ler; C# daha yeni → aynı öncelikte önce gelir.
        var csharp = await AddContentAsync("C# Temelleri", 10, skillNames: "C#");
        var sql = await AddContentAsync("SQL Sorguları", 5, skillNames: "SQL");

        var plan = await GetTodayAsync(userId);

        var learn = TaskOf(plan, "Learn");
        var practice = TaskOf(plan, "Practice");

        Assert.Equal(csharp, learn.ContentId);
        Assert.Contains("C# Temelleri", learn.Description);
        Assert.Contains("Odak beceri: C#", learn.Description);

        Assert.Equal(sql, practice.ContentId);
        Assert.Contains("SQL Sorguları", practice.Description);

        // Tamamlanan ve ilerlemesi olan skill'in içerikleri seçilmedi.
        Assert.DoesNotContain(plan.Tasks, t => t.ContentId == aspDone);
        Assert.DoesNotContain(plan.Tasks, t => t.ContentId == aspNext);

        // Quiz ve Review görevleri içeriğe bağlanmaz (mevcut quiz akışı korunur).
        Assert.Null(TaskOf(plan, "Quiz").ContentId);
    }

    [Fact]
    public async Task InProgressContent_IsContinuedFirst()
    {
        var userId = await CreateUserAsync(60);
        var started = await AddContentAsync("ASP.NET Core İleri", 1, skillNames: "ASP.NET Core");
        var fresh = await AddContentAsync("C# Temelleri", 30, skillNames: "C#");
        await AddProgressAsync(userId, started, completed: false);

        var plan = await GetTodayAsync(userId);

        var learn = TaskOf(plan, "Learn");
        Assert.Equal(started, learn.ContentId);
        Assert.Contains("kaldığın yerden devam", learn.Description);
        Assert.Equal(fresh, TaskOf(plan, "Practice").ContentId);
    }

    [Fact]
    public async Task ContentOutsideUsersProfession_IsNeverSelected()
    {
        // Veri Uzmanı içeriği, Backend skill'i (SQL) ile ilişkili olsa bile seçilmez.
        var otherProfession = await AddContentAsync("SQL ile Veri Analizi", 30, "Veri Uzmanı", "SQL");
        var own = await AddContentAsync("C# Temelleri", 1, skillNames: "C#");
        var userId = await CreateUserAsync(60);

        var plan = await GetTodayAsync(userId);

        Assert.DoesNotContain(plan.Tasks, t => t.ContentId == otherProfession);
        Assert.Equal(own, TaskOf(plan, "Learn").ContentId);
        Assert.Null(TaskOf(plan, "Practice").ContentId); // ikinci uygun içerik yok
    }

    [Fact]
    public async Task SameContent_IsNotUsedTwiceInOnePlan()
    {
        await AddContentAsync("C# Temelleri", 1, skillNames: new[] { "C#", "ASP.NET Core" });
        var userId = await CreateUserAsync(90);

        var plan = await GetTodayAsync(userId);

        var linked = plan.Tasks.Where(t => t.ContentId is not null).Select(t => t.ContentId).ToList();
        Assert.Single(linked);
        Assert.Equal(linked.Count, linked.Distinct().Count());
    }

    [Fact]
    public async Task NoContent_UsesSafeFallback_WithoutError()
    {
        var userId = await CreateUserAsync(60);

        var plan = await GetTodayAsync(userId);

        Assert.Equal(3, plan.Tasks.Count);
        Assert.Equal(60, plan.TotalMinutes);
        Assert.All(plan.Tasks, t => Assert.Null(t.ContentId));
        Assert.Equal(
            "Öğrendiğin konuyla ilgili küçük bir uygulama gerçekleştir.",
            TaskOf(plan, "Practice").Description);
    }

    [Fact]
    public async Task UserWithNoActivity_GetsSpecializationSkillContent_BeforeUnlinkedContent()
    {
        var unlinked = await AddContentAsync("Genel Kariyer İpuçları", 30);
        var linked = await AddContentAsync("REST API Tasarımı", 1, skillNames: "REST API");
        // Backend'de olmayan skill (Python) bağlı içerik: uzmanlık skill'ine bağlı sayılmaz.
        var nonSpecSkill = await AddContentAsync("Python Otomasyon", 20, skillNames: "Python");
        var userId = await CreateUserAsync(60);

        var plan = await GetTodayAsync(userId);

        Assert.Equal(linked, TaskOf(plan, "Learn").ContentId);
        Assert.Contains("Odak beceri: REST API", TaskOf(plan, "Learn").Description);

        // Kalanlar uzmanlık skill'ine bağlı değil: mevcut kural (daha yeni önce).
        Assert.Equal(unlinked, TaskOf(plan, "Practice").ContentId);
        Assert.DoesNotContain(plan.Tasks, t => t.ContentId == nonSpecSkill);
    }

    [Fact]
    public async Task OtherUsersActivity_DoesNotAffectPlan()
    {
        var csharp = await AddContentAsync("C# Temelleri", 30, skillNames: "C#");
        var sql = await AddContentAsync("SQL Sorguları", 1, skillNames: "SQL");

        // Başka kullanıcı C#'ı tamamlamış, SQL'e başlamış.
        var other = await CreateUserAsync(60);
        await AddProgressAsync(other, csharp, completed: true);
        await AddProgressAsync(other, sql, completed: false);

        var me = await CreateUserAsync(60);
        var plan = await GetTodayAsync(me);

        // Benim için ikisi de %0 ve başlanmamış: daha yeni olan C# önce.
        var learn = TaskOf(plan, "Learn");
        Assert.Equal(csharp, learn.ContentId);
        Assert.DoesNotContain("kaldığın yerden devam", learn.Description);
        Assert.Equal(sql, TaskOf(plan, "Practice").ContentId);
    }

    [Fact]
    public async Task SameUserAndData_ProduceSameContentChoices()
    {
        await AddContentAsync("C# Temelleri", 10, skillNames: "C#");
        await AddContentAsync("SQL Sorguları", 10, skillNames: "SQL");
        await AddContentAsync("EF Core", 10, skillNames: "Entity Framework Core");

        var first = await GetTodayAsync(await CreateUserAsync(60));
        var second = await GetTodayAsync(await CreateUserAsync(60));

        Assert.Equal(
            first.Tasks.Select(t => (t.TaskType, t.ContentId, t.EstimatedMinutes)),
            second.Tasks.Select(t => (t.TaskType, t.ContentId, t.EstimatedMinutes)));
    }

    [Fact]
    public async Task ExistingPlanForToday_IsReused_NotRegenerated()
    {
        var userId = await CreateUserAsync(60);
        var first = await GetTodayAsync(userId);

        // Yeni, daha uygun içerik eklense bile aynı gün plan değişmez.
        await AddContentAsync("C# Temelleri", 30, skillNames: "C#");
        var second = await GetTodayAsync(userId);

        Assert.Equal(first.Id, second.Id);
        Assert.Equal(first.Tasks.Select(t => t.ContentId), second.Tasks.Select(t => t.ContentId));
    }
}
