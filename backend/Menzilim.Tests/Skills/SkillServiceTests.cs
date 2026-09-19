using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Services.Skills;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Menzilim.Infrastructure.Repositories;
using Xunit;

namespace Menzilim.Tests.Skills;

/// <summary>
/// SkillService'i gerçek repository'ler ve SQLite in-memory veritabanıyla test eder.
/// </summary>
public sealed class SkillServiceTests : IDisposable
{
    private readonly SqliteConnection _connection;

    public SkillServiceTests()
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

    private static SkillService CreateService(MenzilimDbContext db) =>
        new(
            new UserRepository(db),
            new SkillRepository(db),
            new UserContentProgressRepository(db));

    private async Task<Guid> CreateUserAsync(string? specializationName)
    {
        await using var db = CreateContext();

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

        if (specializationName is not null)
        {
            var specialization = await db.Specializations
                .SingleAsync(s => s.Name == specializationName);

            db.UserProfiles.Add(new UserProfile
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                ProfessionId = specialization.ProfessionId,
                SpecializationId = specialization.Id,
                ExperienceLevel = "Beginner",
                CareerGoal = "Hedef",
                DailyLearningMinutes = 30,
                UpdatedAt = DateTime.UtcNow,
            });
        }

        await db.SaveChangesAsync();
        return user.Id;
    }

    private async Task<Guid> AddContentAsync(string skillName, bool isActive = true)
    {
        await using var db = CreateContext();
        var skill = await db.Skills.SingleAsync(s => s.Name == skillName);

        var content = new Content
        {
            Id = Guid.NewGuid(),
            Title = $"{skillName} içeriği",
            Url = "https://example.com",
            Source = "Test",
            Level = "Beginner",
            PublishedAt = new DateTime(2026, 9, 1),
            IsActive = isActive,
            CreatedAt = DateTime.UtcNow,
        };
        db.Contents.Add(content);
        db.ContentSkills.Add(new ContentSkill
        {
            Id = Guid.NewGuid(),
            ContentId = content.Id,
            SkillId = skill.Id,
        });

        await db.SaveChangesAsync();
        return content.Id;
    }

    private async Task CompleteContentAsync(Guid userId, Guid contentId)
    {
        await using var db = CreateContext();
        db.UserContentProgresses.Add(new UserContentProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ContentId = contentId,
            StartedAt = new DateTime(2026, 9, 1),
            IsCompleted = true,
            CompletedAt = new DateTime(2026, 9, 2),
        });
        await db.SaveChangesAsync();
    }

    private async Task<Guid> AddQuizAsync(string skillName, bool isActive = true)
    {
        await using var db = CreateContext();
        var skill = await db.Skills.SingleAsync(s => s.Name == skillName);

        var quiz = new Quiz
        {
            Id = Guid.NewGuid(),
            Title = $"{skillName} quiz",
            SkillId = skill.Id,
            IsActive = isActive,
            CreatedAt = DateTime.UtcNow,
        };
        db.Quizzes.Add(quiz);
        await db.SaveChangesAsync();
        return quiz.Id;
    }

    private async Task AddAttemptAsync(Guid userId, Guid quizId, int score)
    {
        await using var db = CreateContext();
        db.QuizAttempts.Add(new QuizAttempt
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            QuizId = quizId,
            Score = score,
            CorrectAnswers = 0,
            TotalQuestions = 3,
            CompletedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
    }

    [Fact]
    public async Task GetMyProgressAsync_Throws_WhenUserNotFound()
    {
        await using var db = CreateContext();

        var ex = await Assert.ThrowsAsync<KeyNotFoundException>(
            () => CreateService(db).GetMyProgressAsync(Guid.NewGuid()));

        Assert.Equal("Kullanıcı bulunamadı.", ex.Message);
    }

    [Fact]
    public async Task GetMyProgressAsync_Throws_WhenProfileMissing()
    {
        var userId = await CreateUserAsync(specializationName: null);
        await using var db = CreateContext();

        var ex = await Assert.ThrowsAsync<KeyNotFoundException>(
            () => CreateService(db).GetMyProgressAsync(userId));

        Assert.Equal("Kullanıcı profili bulunamadı.", ex.Message);
    }

    [Fact]
    public async Task GetMyProgressAsync_MatchesEngineResult_ForSameData()
    {
        var userId = await CreateUserAsync("Backend");
        var content = await AddContentAsync("SQL");
        await AddContentAsync("SQL");
        await CompleteContentAsync(userId, content);
        var quiz = await AddQuizAsync("SQL");
        await AddAttemptAsync(userId, quiz, 80);

        await using var db = CreateContext();
        var actual = await CreateService(db).GetMyProgressAsync(userId);

        // Aynı veriyi doğrudan engine'e ver; sonuç birebir aynı olmalı.
        var specializationId = (await db.UserProfiles.SingleAsync(p => p.UserId == userId))
            .SpecializationId;
        var skills = await db.SpecializationSkills
            .Where(ss => ss.SpecializationId == specializationId)
            .Select(ss => ss.Skill)
            .ToListAsync();

        var expected = SkillProgressEngine.Calculate(
            userId,
            skills,
            await db.ContentSkills.ToListAsync(),
            await db.UserContentProgresses.ToListAsync(),
            await db.Quizzes.ToListAsync(),
            await db.QuizAttempts.ToListAsync());

        Assert.Equal(expected.Count, actual.Count);
        for (var i = 0; i < expected.Count; i++)
        {
            Assert.Equivalent(expected[i], actual[i], strict: true);
        }

        // İçerik 1/2 = 50, quiz 80 → 65
        Assert.Equal(65, actual.Single(s => s.SkillName == "SQL").ProgressPercent);
    }

    [Fact]
    public async Task GetMyProgressAsync_ExcludesSkillsOutsideSpecialization()
    {
        var userId = await CreateUserAsync("Backend");

        // Python Backend'de yok; aktivitesi olsa bile görünmemeli.
        var python = await AddContentAsync("Python");
        await CompleteContentAsync(userId, python);

        await using var db = CreateContext();
        var result = await CreateService(db).GetMyProgressAsync(userId);

        Assert.DoesNotContain(result, s => s.SkillName == "Python");
        Assert.Equal(SkillSeeder.SpecializationSkills["Backend"].Length, result.Count);
        Assert.All(result, s => Assert.Equal(0, s.ProgressPercent));
    }

    [Fact]
    public async Task GetMyProgressAsync_IgnoresInactiveContentAndQuizzes()
    {
        var userId = await CreateUserAsync("Backend");
        var active = await AddContentAsync("SQL");
        var inactive = await AddContentAsync("SQL", isActive: false);
        await CompleteContentAsync(userId, inactive);
        var inactiveQuiz = await AddQuizAsync("SQL", isActive: false);
        await AddAttemptAsync(userId, inactiveQuiz, 100);

        await using var db = CreateContext();
        var sql = (await CreateService(db).GetMyProgressAsync(userId))
            .Single(s => s.SkillName == "SQL");

        Assert.Equal(1, sql.TotalContentCount);
        Assert.Equal(0, sql.CompletedContentCount);
        Assert.Equal(0, sql.TotalQuizCount);
        Assert.Equal(0, sql.QuizAttemptCount);
        Assert.Equal(0, sql.ProgressPercent);
        Assert.NotEqual(Guid.Empty, active);
    }

    [Fact]
    public async Task GetMyProgressAsync_IgnoresOtherUsersActivity()
    {
        var me = await CreateUserAsync("Backend");
        var other = await CreateUserAsync("Backend");
        var content = await AddContentAsync("SQL");
        await CompleteContentAsync(other, content);
        var quiz = await AddQuizAsync("SQL");
        await AddAttemptAsync(other, quiz, 100);

        await using var db = CreateContext();
        var sql = (await CreateService(db).GetMyProgressAsync(me))
            .Single(s => s.SkillName == "SQL");

        Assert.Equal(0, sql.ProgressPercent);
        Assert.Equal(0, sql.CompletedContentCount);
        Assert.Equal(0, sql.QuizAttemptCount);
    }

    [Fact]
    public async Task GetBySpecializationAsync_ReturnsSortedActiveSkills()
    {
        await using var db = CreateContext();
        var specialization = await db.Specializations.SingleAsync(s => s.Name == "Frontend");

        var result = await CreateService(db).GetBySpecializationAsync(specialization.Id);

        Assert.Equal(
            SkillSeeder.SpecializationSkills["Frontend"].OrderBy(n => n, StringComparer.Ordinal),
            result.Select(s => s.Name));

        var again = await CreateService(db).GetBySpecializationAsync(specialization.Id);
        Assert.Equal(result.Select(s => s.Id), again.Select(s => s.Id));
    }

    [Fact]
    public async Task GetBySpecializationAsync_Throws_WhenSpecializationMissing()
    {
        await using var db = CreateContext();

        var ex = await Assert.ThrowsAsync<KeyNotFoundException>(
            () => CreateService(db).GetBySpecializationAsync(Guid.NewGuid()));

        Assert.Equal("Uzmanlık bulunamadı.", ex.Message);
    }
}
