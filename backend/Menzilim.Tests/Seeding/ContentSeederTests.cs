using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Seeding;

/// <summary>
/// İçerik/quiz seed'ini gerçek bir ilişkisel veritabanında (SQLite in-memory)
/// çalıştırır; unique index ve foreign key kısıtları gerçekten uygulanır.
/// </summary>
public sealed class ContentSeederTests : IDisposable
{
    private static readonly string[] SoftwareSpecializations =
        { "Frontend", "Backend", "Full Stack", "Mobile" };

    private readonly SqliteConnection _connection;

    public ContentSeederTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        using var db = CreateContext();
        db.Database.EnsureCreated();
    }

    public void Dispose() => _connection.Dispose();

    private MenzilimDbContext CreateContext() =>
        new(new DbContextOptionsBuilder<MenzilimDbContext>()
            .UseSqlite(_connection)
            .Options);

    // Uygulama açılışındaki sırayla: referans veriler, sonra içerik.
    private async Task<IReadOnlyList<string>> SeedAllAsync()
    {
        await using var db = CreateContext();
        await DatabaseSeeder.SeedAsync(db);
        return await ContentSeeder.SeedAsync(db);
    }

    private static int ExpectedContentSkillCount() =>
        ContentSeeder.Contents.Sum(c => c.SkillNames.Length);

    [Fact]
    public void Catalog_IsConsistent()
    {
        var skillNames = SkillSeeder.Skills.Select(s => s.Name).ToHashSet();

        var titles = ContentSeeder.Contents.Select(c => c.Title).ToList();
        Assert.Equal(titles.Count, titles.Distinct(StringComparer.OrdinalIgnoreCase).Count());

        foreach (var content in ContentSeeder.Contents)
        {
            Assert.True(
                Uri.TryCreate(content.Url, UriKind.Absolute, out var uri) &&
                uri.Scheme == Uri.UriSchemeHttps,
                $"geçersiz URL: {content.Url}");
            Assert.False(string.IsNullOrWhiteSpace(content.Description));
            Assert.False(string.IsNullOrWhiteSpace(content.Source));
            Assert.InRange(content.ReadingTimeMinutes, 5, 120);
            Assert.NotEmpty(content.SkillNames);
            Assert.All(content.SkillNames, name => Assert.Contains(name, skillNames));
        }

        var quizTitles = ContentSeeder.Quizzes.Select(q => q.Title).ToList();
        Assert.Equal(quizTitles.Count, quizTitles.Distinct(StringComparer.OrdinalIgnoreCase).Count());
        Assert.DoesNotContain("ASP.NET Core Temelleri", quizTitles);

        foreach (var quiz in ContentSeeder.Quizzes)
        {
            Assert.Contains(quiz.SkillName, skillNames);
            Assert.True(quiz.Questions.Length >= 3, $"{quiz.Title}: en az 3 soru olmalı");
            Assert.All(quiz.Questions, q =>
            {
                Assert.Contains(q.CorrectOption, new[] { "A", "B", "C", "D" });
                Assert.All(
                    new[] { q.Text, q.OptionA, q.OptionB, q.OptionC, q.OptionD },
                    text => Assert.False(string.IsNullOrWhiteSpace(text)));
            });
        }
    }

    [Fact]
    public void Catalog_CoversEverySoftwareSpecialization_ThroughItsSkills()
    {
        foreach (var specialization in SoftwareSpecializations)
        {
            var specSkills = SkillSeeder.SpecializationSkills[specialization].ToHashSet();

            var contentCount = ContentSeeder.Contents
                .Count(c => c.SkillNames.Any(specSkills.Contains));

            Assert.True(contentCount >= 3, $"{specialization}: {contentCount} içerik");

            // Her uzmanlığın kendi skill'lerinden birine bağlı en az bir yeni quiz.
            Assert.Contains(ContentSeeder.Quizzes, q => specSkills.Contains(q.SkillName));

            // Günlük plan seçicisinin uzmanlık adı eşleşmesi için açıklamada geçer.
            Assert.Contains(ContentSeeder.Contents, c =>
                c.Description.Contains(specialization, StringComparison.OrdinalIgnoreCase));
        }
    }

    [Fact]
    public async Task SeedAsync_OnCleanDatabase_CreatesContentProfessionSkillLinksAndQuizzes()
    {
        var warnings = await SeedAllAsync();

        Assert.Empty(warnings);

        await using var verify = CreateContext();

        var software = await verify.Professions
            .SingleAsync(p => p.Name == ContentSeeder.SoftwareProfessionName);

        var contents = await verify.Contents
            .Include(c => c.Professions)
            .Include(c => c.Skills).ThenInclude(cs => cs.Skill)
            .ToListAsync();

        Assert.Equal(ContentSeeder.Contents.Count, contents.Count);
        Assert.All(contents, c => Assert.True(c.IsActive));

        foreach (var definition in ContentSeeder.Contents)
        {
            var content = contents.Single(c => c.Title == definition.Title);

            Assert.Equal(definition.Url, content.Url);
            Assert.Equal(definition.ReadingTimeMinutes, content.ReadingTimeMinutes);

            // Yalnızca Yazılım Geliştirici mesleğine, tam bir kez bağlı.
            Assert.Equal(software.Id, Assert.Single(content.Professions).ProfessionId);

            Assert.Equal(
                definition.SkillNames.OrderBy(n => n, StringComparer.Ordinal),
                content.Skills.Select(cs => cs.Skill.Name).OrderBy(n => n, StringComparer.Ordinal));
        }

        Assert.Equal(ExpectedContentSkillCount(), await verify.ContentSkills.CountAsync());

        // Mevcut ASP.NET quiz'i korunur, yeni quiz'ler eklenir.
        var quizzes = await verify.Quizzes
            .Include(q => q.Questions)
            .Include(q => q.Skill)
            .ToListAsync();

        Assert.Equal(1 + ContentSeeder.Quizzes.Count, quizzes.Count);
        Assert.Equal("ASP.NET Core", quizzes.Single(q => q.Title == "ASP.NET Core Temelleri").Skill!.Name);

        foreach (var definition in ContentSeeder.Quizzes)
        {
            var quiz = quizzes.Single(q => q.Title == definition.Title);

            Assert.True(quiz.IsActive);
            Assert.Equal(definition.SkillName, quiz.Skill!.Name);
            Assert.Equal(definition.Questions.Length, quiz.Questions.Count);
            Assert.Equal(
                definition.Questions.Select(q => q.CorrectOption).OrderBy(o => o),
                quiz.Questions.Select(q => q.CorrectOption).OrderBy(o => o));
        }
    }

    [Fact]
    public async Task SeedAsync_OnCleanDatabase_EachSoftwareSpecializationHasLinkedContent()
    {
        await SeedAllAsync();

        await using var verify = CreateContext();

        foreach (var name in SoftwareSpecializations)
        {
            var specialization = await verify.Specializations.SingleAsync(s => s.Name == name);

            var specSkillIds = await verify.SpecializationSkills
                .Where(ss => ss.SpecializationId == specialization.Id)
                .Select(ss => ss.SkillId)
                .ToListAsync();

            // Günlük plan / skill ilerlemesi bu ilişki üzerinden içerik bulur.
            var linkedContentCount = await verify.ContentSkills
                .Where(cs => specSkillIds.Contains(cs.SkillId) && cs.Content.IsActive)
                .Select(cs => cs.ContentId)
                .Distinct()
                .CountAsync();

            Assert.True(linkedContentCount >= 3, $"{name}: {linkedContentCount} içerik");

            // İçerikler uzmanlığın mesleğine bağlı (öneri ve plan kapsamı).
            var professionContentCount = await verify.ContentProfessions
                .CountAsync(cp => cp.ProfessionId == specialization.ProfessionId);

            Assert.Equal(ContentSeeder.Contents.Count, professionContentCount);
        }
    }

    [Fact]
    public async Task SeedAsync_IsIdempotent_WhenRunTwice()
    {
        await SeedAllAsync();

        int contents, professionLinks, skillLinks, quizzes, questions;
        await using (var check = CreateContext())
        {
            contents = await check.Contents.CountAsync();
            professionLinks = await check.ContentProfessions.CountAsync();
            skillLinks = await check.ContentSkills.CountAsync();
            quizzes = await check.Quizzes.CountAsync();
            questions = await check.Questions.CountAsync();
        }

        // Ayrı bir context ile (uygulamanın yeniden açılması gibi) tekrar çalıştır.
        var warnings = await SeedAllAsync();

        Assert.Empty(warnings);

        await using var verify = CreateContext();

        Assert.Equal(contents, await verify.Contents.CountAsync());
        Assert.Equal(professionLinks, await verify.ContentProfessions.CountAsync());
        Assert.Equal(skillLinks, await verify.ContentSkills.CountAsync());
        Assert.Equal(quizzes, await verify.Quizzes.CountAsync());
        Assert.Equal(questions, await verify.Questions.CountAsync());

        Assert.Equal(ContentSeeder.Contents.Count, contents);
        Assert.Equal(ContentSeeder.Contents.Count, professionLinks);
        Assert.Equal(ExpectedContentSkillCount(), skillLinks);
        Assert.Equal(1 + ContentSeeder.Quizzes.Count, quizzes);
    }

    [Fact]
    public async Task SeedAsync_ReusesExistingContentWithSameTitle_WithoutChangingIt()
    {
        const string title = "ASP.NET Core Web API Development";

        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);

            // Elle (POST /api/content ile) eklenmiş, meslek/skill bağlantısı olmayan içerik.
            db.Contents.Add(new Content
            {
                Id = Guid.NewGuid(),
                Title = title,
                Description = "Elle eklenmiş açıklama",
                Url = "https://learn.microsoft.com/aspnet/core/web-api/",
                Source = "Microsoft Learn",
                PublishedAt = new DateTime(2026, 9, 17),
                ReadingTimeMinutes = 10,
                Level = "Beginner",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
            });
            await db.SaveChangesAsync();
        }

        await using (var db = CreateContext())
        {
            Assert.Empty(await ContentSeeder.SeedAsync(db));
        }

        await using var verify = CreateContext();

        var content = await verify.Contents
            .Include(c => c.Professions)
            .Include(c => c.Skills).ThenInclude(cs => cs.Skill)
            .SingleAsync(c => c.Title == title);

        Assert.Equal("Elle eklenmiş açıklama", content.Description);
        Assert.Single(content.Professions);
        Assert.Equal("ASP.NET Core", Assert.Single(content.Skills).Skill.Name);
        Assert.Equal(ContentSeeder.Contents.Count, await verify.Contents.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_KeepsExistingQuizWithSameTitle_AndItsQuestions()
    {
        var title = ContentSeeder.Quizzes[0].Title;

        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);

            var quiz = new Quiz
            {
                Id = Guid.NewGuid(),
                Title = title,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
            };
            quiz.Questions.Add(new Question
            {
                Id = Guid.NewGuid(),
                QuizId = quiz.Id,
                Text = "Elle eklenmiş soru",
                OptionA = "a",
                OptionB = "b",
                OptionC = "c",
                OptionD = "d",
                CorrectOption = "A",
            });
            db.Quizzes.Add(quiz);
            await db.SaveChangesAsync();
        }

        await using (var db = CreateContext())
        {
            await ContentSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();

        var existing = await verify.Quizzes
            .Include(q => q.Questions)
            .SingleAsync(q => q.Title == title);

        Assert.Equal("Elle eklenmiş soru", Assert.Single(existing.Questions).Text);
        Assert.Equal(1 + ContentSeeder.Quizzes.Count, await verify.Quizzes.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_SkipsLinksAndWarns_WhenContentTitleIsAmbiguous()
    {
        var title = ContentSeeder.Contents[0].Title;

        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);

            for (var i = 0; i < 2; i++)
            {
                db.Contents.Add(new Content
                {
                    Id = Guid.NewGuid(),
                    Title = title,
                    Url = "https://web.dev/learn/html",
                    Source = "web.dev",
                    PublishedAt = new DateTime(2026, 9, 1),
                    ReadingTimeMinutes = 10,
                    Level = "Beginner",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                });
            }
            await db.SaveChangesAsync();
        }

        IReadOnlyList<string> warnings;
        await using (var db = CreateContext())
        {
            warnings = await ContentSeeder.SeedAsync(db);
        }

        Assert.Contains(warnings, w => w.Contains(title) && w.Contains("belirsiz"));

        await using var verify = CreateContext();

        Assert.Equal(2, await verify.Contents.CountAsync(c => c.Title == title));
        Assert.False(await verify.ContentSkills.AnyAsync(cs => cs.Content.Title == title));
        Assert.False(await verify.ContentProfessions.AnyAsync(cp => cp.Content.Title == title));
    }
}
