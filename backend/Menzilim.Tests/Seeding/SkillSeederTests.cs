using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Seeding;

/// <summary>
/// Seed'i gerçek bir ilişkisel veritabanında (SQLite in-memory) çalıştırır;
/// unique index ve foreign key kısıtları gerçekten uygulanır.
/// </summary>
public sealed class SkillSeederTests : IDisposable
{
    private readonly SqliteConnection _connection;

    public SkillSeederTests()
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

    private static int ExpectedLinkCount() =>
        SkillSeeder.SpecializationSkills.Values.Sum(names => names.Length);

    [Fact]
    public void Catalog_IsConsistent()
    {
        var names = SkillSeeder.Skills.Select(s => s.Name).ToList();

        // Katalogda aynı isim iki kez tanımlanmamalı (büyük/küçük harf duyarsız).
        Assert.Equal(
            names.Count,
            names.Distinct(StringComparer.OrdinalIgnoreCase).Count());

        foreach (var (specialization, skillNames) in SkillSeeder.SpecializationSkills)
        {
            // Her uzmanlıkta MVP için 5-8 skill.
            Assert.InRange(skillNames.Length, 5, 8);
            Assert.Equal(skillNames.Length, skillNames.Distinct().Count());

            // Eşleştirmedeki her skill katalogda tanımlı olmalı.
            Assert.All(skillNames, name => Assert.Contains(name, names));
        }

        // Her katalog skill'i en az bir uzmanlıkta kullanılmalı.
        var used = SkillSeeder.SpecializationSkills.Values
            .SelectMany(n => n)
            .ToHashSet();
        Assert.All(names, name => Assert.Contains(name, used));
    }

    [Fact]
    public async Task SeedAsync_CreatesSkillsAndLinks_ForAllSpecializations()
    {
        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();

        Assert.Equal(SkillSeeder.Skills.Count, await verify.Skills.CountAsync());
        Assert.Equal(ExpectedLinkCount(), await verify.SpecializationSkills.CountAsync());

        // Ortak skill tek kayıt olarak birden fazla uzmanlığa bağlı.
        var sql = await verify.Skills
            .Include(s => s.SpecializationSkills)
                .ThenInclude(ss => ss.Specialization)
            .SingleAsync(s => s.Name == "SQL");

        Assert.Equal(
            new[] { "Backend", "Data Analyst", "Data Science", "Full Stack" },
            sql.SpecializationSkills
                .Select(ss => ss.Specialization.Name)
                .OrderBy(n => n, StringComparer.Ordinal));

        // Türkçe karakterler bozulmadan saklanır.
        Assert.True(await verify.Skills.AnyAsync(s => s.Name == "İstatistik"));
        Assert.True(await verify.Skills.AnyAsync(s => s.Name == "Sızma Testi Metodolojisi"));
    }

    [Fact]
    public async Task SeedAsync_IsIdempotent_WhenRunTwice()
    {
        await using (var first = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(first);
        }

        await using (var second = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(second);
        }

        await using var verify = CreateContext();

        Assert.Equal(SkillSeeder.Skills.Count, await verify.Skills.CountAsync());
        Assert.Equal(ExpectedLinkCount(), await verify.SpecializationSkills.CountAsync());

        // Mevcut profession, specialization ve quiz seed'leri de tekrarlanmaz.
        Assert.Equal(3, await verify.Professions.CountAsync());
        Assert.Equal(10, await verify.Specializations.CountAsync());
        Assert.Equal(1, await verify.Quizzes.CountAsync());

        // Bu testte içerik yok: ContentSkill oluşmaz. Seed'lenen quiz eşleşir.
        // UserSkill hiçbir zaman otomatik doldurulmaz.
        Assert.Equal(0, await verify.ContentSkills.CountAsync());
        Assert.Equal(0, await verify.UserSkills.CountAsync());
        Assert.Equal(1, await verify.Quizzes.CountAsync(q => q.SkillId != null));
    }

    [Fact]
    public async Task SeedAsync_KeepsExistingData_AndOnlyAddsMissing()
    {
        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);

            // Bir skill'in açıklaması elle değiştirilmiş, bir ilişki silinmiş olsun.
            var sql = await db.Skills.SingleAsync(s => s.Name == "SQL");
            sql.Description = "Elle güncellenmiş açıklama";

            var link = await db.SpecializationSkills
                .FirstAsync(ss => ss.SkillId == sql.Id);
            db.SpecializationSkills.Remove(link);

            await db.SaveChangesAsync();
        }

        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();

        // Mevcut skill güncellenmez, eksik ilişki geri eklenir, duplicate oluşmaz.
        var reloaded = await verify.Skills.SingleAsync(s => s.Name == "SQL");
        Assert.Equal("Elle güncellenmiş açıklama", reloaded.Description);
        Assert.Equal(SkillSeeder.Skills.Count, await verify.Skills.CountAsync());
        Assert.Equal(ExpectedLinkCount(), await verify.SpecializationSkills.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_MatchesExistingSkillName_CaseInsensitively()
    {
        await using (var db = CreateContext())
        {
            db.Skills.Add(new Skill
            {
                Id = Guid.NewGuid(),
                Name = "sql",
                Category = "Veritabanı",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
            });
            await db.SaveChangesAsync();

            await DatabaseSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();

        // "sql" mevcut kayıt olarak kullanılır; ayrı bir "SQL" eklenmez.
        Assert.Equal(SkillSeeder.Skills.Count, await verify.Skills.CountAsync());
        Assert.Equal(ExpectedLinkCount(), await verify.SpecializationSkills.CountAsync());
    }

    private const string AspNetContentTitle = "ASP.NET Core Web API Development";

    private static Content MakeContent(string title) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Description = "Learn the basics of building Web APIs with ASP.NET Core.",
            Url = "https://learn.microsoft.com/aspnet/core/web-api/",
            Source = "Microsoft Learn",
            Level = "Beginner",
            PublishedAt = new DateTime(2026, 9, 17),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
        };

    private async Task<Guid> AddContentAsync(string title)
    {
        await using var db = CreateContext();
        var content = MakeContent(title);
        db.Contents.Add(content);
        await db.SaveChangesAsync();
        return content.Id;
    }

    [Fact]
    public async Task SeedAsync_MapsContentAndQuiz_ToAspNetCore()
    {
        var contentId = await AddContentAsync(AspNetContentTitle);

        IReadOnlyList<string> warnings;
        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);
            warnings = await SkillSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();
        var aspNet = await verify.Skills.SingleAsync(s => s.Name == "ASP.NET Core");

        var contentSkill = await verify.ContentSkills.SingleAsync();
        Assert.Equal(contentId, contentSkill.ContentId);
        Assert.Equal(aspNet.Id, contentSkill.SkillId);

        var quiz = await verify.Quizzes.SingleAsync(q => q.Title == "ASP.NET Core Temelleri");
        Assert.Equal(aspNet.Id, quiz.SkillId);

        Assert.Empty(warnings);
    }

    [Fact]
    public async Task SeedAsync_DoesNotMapContent_ToRestApi()
    {
        await AddContentAsync(AspNetContentTitle);

        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();
        var restApi = await verify.Skills.SingleAsync(s => s.Name == "REST API");

        Assert.False(await verify.ContentSkills.AnyAsync(cs => cs.SkillId == restApi.Id));
    }

    [Fact]
    public async Task SeedAsync_ContentAndQuizMappings_AreIdempotent()
    {
        await AddContentAsync(AspNetContentTitle);

        await using (var first = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(first);
        }

        Guid? quizSkillAfterFirst;
        await using (var check = CreateContext())
        {
            quizSkillAfterFirst = (await check.Quizzes.SingleAsync()).SkillId;
        }

        await using (var second = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(second);
        }

        await using var verify = CreateContext();

        Assert.Equal(1, await verify.ContentSkills.CountAsync());
        Assert.Equal(quizSkillAfterFirst, (await verify.Quizzes.SingleAsync()).SkillId);

        // Diğer seed verileri korunur.
        Assert.Equal(SkillSeeder.Skills.Count, await verify.Skills.CountAsync());
        Assert.Equal(ExpectedLinkCount(), await verify.SpecializationSkills.CountAsync());
        Assert.Equal(3, await verify.Professions.CountAsync());
        Assert.Equal(10, await verify.Specializations.CountAsync());
        Assert.Equal(1, await verify.Contents.CountAsync());
        Assert.Equal(0, await verify.UserSkills.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_KeepsExistingQuizSkill_AndWarns()
    {
        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);

            // Quiz elle başka bir skill'e bağlanmış olsun.
            var csharp = await db.Skills.SingleAsync(s => s.Name == "C#");
            var quiz = await db.Quizzes.SingleAsync();
            quiz.SkillId = csharp.Id;
            await db.SaveChangesAsync();
        }

        IReadOnlyList<string> warnings;
        await using (var db = CreateContext())
        {
            warnings = await SkillSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();
        var csharpId = (await verify.Skills.SingleAsync(s => s.Name == "C#")).Id;

        Assert.Equal(csharpId, (await verify.Quizzes.SingleAsync()).SkillId);
        Assert.Contains(warnings, w => w.Contains("mevcut değer korundu"));
    }

    [Fact]
    public async Task SeedAsync_SkipsAndWarns_WhenContentMissing()
    {
        IReadOnlyList<string> warnings;
        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);
            warnings = await SkillSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();

        Assert.Equal(0, await verify.ContentSkills.CountAsync());
        Assert.Contains(warnings, w =>
            w.Contains(AspNetContentTitle) && w.Contains("bulunamadı"));
    }

    [Fact]
    public async Task SeedAsync_SkipsAndWarns_WhenContentTitleIsAmbiguous()
    {
        await AddContentAsync(AspNetContentTitle);
        await AddContentAsync(AspNetContentTitle);

        IReadOnlyList<string> warnings;
        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);
            warnings = await SkillSeeder.SeedAsync(db);
        }

        await using var verify = CreateContext();

        Assert.Equal(0, await verify.ContentSkills.CountAsync());
        Assert.Contains(warnings, w => w.Contains("belirsiz"));
    }
}
