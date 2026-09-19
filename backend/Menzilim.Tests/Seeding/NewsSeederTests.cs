using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Seeding;

/// <summary>
/// Haber seed'ini gerçek bir ilişkisel veritabanında (SQLite in-memory)
/// çalıştırır; unique index ve foreign key kısıtları gerçekten uygulanır.
/// </summary>
public sealed class NewsSeederTests : IDisposable
{
    private static readonly string[] SoftwareSpecializations =
        { "Frontend", "Backend", "Full Stack", "Mobile" };

    private readonly SqliteConnection _connection;

    public NewsSeederTests()
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

    // Uygulama açılışındaki sırayla.
    private async Task<IReadOnlyList<string>> SeedAllAsync()
    {
        await using var db = CreateContext();
        await DatabaseSeeder.SeedAsync(db);
        await ContentSeeder.SeedAsync(db);
        return await NewsSeeder.SeedAsync(db);
    }

    [Fact]
    public void Catalog_IsConsistent()
    {
        Assert.True(NewsSeeder.News.Count >= 10);

        var skillNames = SkillSeeder.Skills.Select(s => s.Name).ToHashSet();

        var urls = NewsSeeder.News.Select(n => n.SourceUrl).ToList();
        Assert.Equal(urls.Count, urls.Distinct(StringComparer.OrdinalIgnoreCase).Count());

        foreach (var news in NewsSeeder.News)
        {
            Assert.True(
                Uri.TryCreate(news.SourceUrl, UriKind.Absolute, out var uri) &&
                uri.Scheme == Uri.UriSchemeHttps,
                $"geçersiz URL: {news.SourceUrl}");
            Assert.True(news.SourceUrl.Length <= 450, "SourceUrl unique index sınırı");
            Assert.False(string.IsNullOrWhiteSpace(news.Title));
            Assert.False(string.IsNullOrWhiteSpace(news.Summary));
            Assert.False(string.IsNullOrWhiteSpace(news.SourceName));
            Assert.Equal(DateTimeKind.Utc, news.PublishedAt.Kind);
            Assert.NotEmpty(news.SkillNames);
            Assert.All(news.SkillNames, name => Assert.Contains(name, skillNames));
        }
    }

    [Fact]
    public void Catalog_CoversEverySoftwareSpecialization_ThroughItsSkills()
    {
        foreach (var specialization in SoftwareSpecializations)
        {
            var specSkills = SkillSeeder.SpecializationSkills[specialization].ToHashSet();

            var count = NewsSeeder.News.Count(n => n.SkillNames.Any(specSkills.Contains));

            Assert.True(count >= 2, $"{specialization}: {count} haber");
        }
    }

    [Fact]
    public async Task SeedAsync_OnCleanDatabase_CreatesNewsAndSkillLinks()
    {
        var warnings = await SeedAllAsync();

        Assert.Empty(warnings);

        await using var verify = CreateContext();

        var news = await verify.NewsItems
            .Include(n => n.Skills).ThenInclude(ns => ns.Skill)
            .ToListAsync();

        Assert.Equal(NewsSeeder.News.Count, news.Count);
        Assert.All(news, n => Assert.True(n.IsActive));
        Assert.All(news, n => Assert.Null(n.ImageUrl));

        foreach (var definition in NewsSeeder.News)
        {
            var item = news.Single(n => n.SourceUrl == definition.SourceUrl);

            Assert.Equal(definition.Title, item.Title);
            Assert.Equal(definition.PublishedAt, item.PublishedAt);
            Assert.Equal(
                definition.SkillNames.OrderBy(n => n, StringComparer.Ordinal),
                item.Skills.Select(s => s.Skill.Name).OrderBy(n => n, StringComparer.Ordinal));
        }

        // Öğrenme içerikleri ayrı kalır.
        Assert.Equal(ContentSeeder.Contents.Count, await verify.Contents.CountAsync());
    }

    [Fact]
    public async Task SeedAsync_IsIdempotent_WhenRunTwice()
    {
        await SeedAllAsync();

        int news, links;
        await using (var check = CreateContext())
        {
            news = await check.NewsItems.CountAsync();
            links = await check.NewsItemSkills.CountAsync();
        }

        var warnings = await SeedAllAsync();

        Assert.Empty(warnings);

        await using var verify = CreateContext();

        Assert.Equal(news, await verify.NewsItems.CountAsync());
        Assert.Equal(links, await verify.NewsItemSkills.CountAsync());
        Assert.Equal(NewsSeeder.News.Count, news);
        Assert.Equal(NewsSeeder.News.Sum(n => n.SkillNames.Length), links);
    }

    [Fact]
    public async Task SeedAsync_KeepsExistingNewsWithSameUrl_AndOnlyAddsMissingLinks()
    {
        var definition = NewsSeeder.News[0];

        await using (var db = CreateContext())
        {
            await DatabaseSeeder.SeedAsync(db);

            db.NewsItems.Add(new NewsItem
            {
                Id = Guid.NewGuid(),
                Title = "Elle düzenlenmiş başlık",
                Summary = "Elle düzenlenmiş özet",
                SourceName = "Editör",
                // Farklı büyük/küçük harf: SQL Server collation'ında aynı kayıt.
                SourceUrl = definition.SourceUrl.ToUpperInvariant(),
                PublishedAt = definition.PublishedAt,
                IsActive = false,
                CreatedAt = DateTime.UtcNow,
            });
            await db.SaveChangesAsync();
        }

        await using (var db = CreateContext())
        {
            Assert.Empty(await NewsSeeder.SeedAsync(db));
        }

        await using var verify = CreateContext();

        var existing = await verify.NewsItems
            .Include(n => n.Skills)
            .SingleAsync(n => n.Title == "Elle düzenlenmiş başlık");

        // Mevcut kayıt değiştirilmez (pasif kalır), bağlantıları tamamlanır.
        Assert.False(existing.IsActive);
        Assert.Equal(definition.SkillNames.Length, existing.Skills.Count);
        Assert.Equal(NewsSeeder.News.Count, await verify.NewsItems.CountAsync());
    }
}
