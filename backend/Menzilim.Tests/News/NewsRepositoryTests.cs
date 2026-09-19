using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Menzilim.Infrastructure.Repositories;
using Xunit;

namespace Menzilim.Tests.News;

/// <summary>
/// NewsRepository sorgularını gerçek bir ilişkisel veritabanında (SQLite
/// in-memory) test eder: filtreleme, sıralama ve sınır veritabanında uygulanır.
/// Referans veriler (meslek/uzmanlık/skill) DatabaseSeeder ile oluşturulur;
/// haberler her testte kontrollü eklenir.
/// </summary>
public sealed class NewsRepositoryTests : IDisposable
{
    private static readonly DateTime T0 = new(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    private readonly SqliteConnection _connection;

    public NewsRepositoryTests()
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

    private async Task<Guid> SpecializationIdAsync(string name)
    {
        await using var db = CreateContext();
        return (await db.Specializations.SingleAsync(s => s.Name == name)).Id;
    }

    private async Task<Guid> ProfessionIdAsync(string name)
    {
        await using var db = CreateContext();
        return (await db.Professions.SingleAsync(p => p.Name == name)).Id;
    }

    private async Task<NewsItem> AddNewsAsync(
        string title,
        DateTime publishedAt,
        string[] skillNames,
        bool isActive = true,
        Guid? id = null)
    {
        await using var db = CreateContext();

        var news = new NewsItem
        {
            Id = id ?? Guid.NewGuid(),
            Title = title,
            Summary = $"{title} özeti",
            SourceName = "Test",
            SourceUrl = $"https://example.com/{Guid.NewGuid():N}",
            PublishedAt = publishedAt,
            IsActive = isActive,
            CreatedAt = T0,
        };

        foreach (var skillName in skillNames)
        {
            var skill = await db.Skills.SingleAsync(s => s.Name == skillName);
            news.Skills.Add(new NewsItemSkill
            {
                Id = Guid.NewGuid(),
                NewsItemId = news.Id,
                SkillId = skill.Id,
            });
        }

        db.NewsItems.Add(news);
        await db.SaveChangesAsync();
        return news;
    }

    private async Task<List<NewsItem>> BySpecializationAsync(string name, int take = 10)
    {
        await using var db = CreateContext();
        return await new NewsRepository(db)
            .GetActiveBySpecializationAsync(await SpecializationIdAsync(name), take);
    }

    [Fact]
    public async Task BySpecialization_ReturnsOnlyNewsLinkedToSpecializationSkills()
    {
        await AddNewsAsync("C# haberi", T0, new[] { "C#" });            // Backend
        await AddNewsAsync("Flutter haberi", T0, new[] { "Flutter" });  // Mobile
        await AddNewsAsync("Skill'siz haber", T0, Array.Empty<string>());

        var backend = await BySpecializationAsync("Backend");
        var mobile = await BySpecializationAsync("Mobile");

        Assert.Equal(new[] { "C# haberi" }, backend.Select(n => n.Title));
        Assert.Equal(new[] { "Flutter haberi" }, mobile.Select(n => n.Title));
    }

    [Fact]
    public async Task BySpecialization_NewsLinkedToSeveralMatchingSkills_AppearsOnce()
    {
        await AddNewsAsync(".NET haberi", T0, new[] { "C#", "ASP.NET Core", "SQL" });

        var backend = await BySpecializationAsync("Backend");

        Assert.Single(backend);
    }

    [Fact]
    public async Task BySpecialization_FiltersInactiveNews_AndInactiveSkills()
    {
        await AddNewsAsync("Aktif", T0, new[] { "C#" });
        await AddNewsAsync("Pasif haber", T0.AddDays(1), new[] { "C#" }, isActive: false);
        await AddNewsAsync("Pasif skill", T0.AddDays(2), new[] { "SQL" });

        await using (var db = CreateContext())
        {
            var sql = await db.Skills.SingleAsync(s => s.Name == "SQL");
            sql.IsActive = false;
            await db.SaveChangesAsync();
        }

        var backend = await BySpecializationAsync("Backend");

        Assert.Equal(new[] { "Aktif" }, backend.Select(n => n.Title));
    }

    [Fact]
    public async Task BySpecialization_SortsByPublishedAtDescending_AndLimits()
    {
        for (var i = 0; i < 12; i++)
        {
            await AddNewsAsync($"Haber {i:00}", T0.AddDays(i), new[] { "C#" });
        }

        var backend = await BySpecializationAsync("Backend", take: 10);

        Assert.Equal(10, backend.Count);
        Assert.Equal(
            Enumerable.Range(2, 10).Reverse().Select(i => $"Haber {i:00}"),
            backend.Select(n => n.Title));
    }

    [Fact]
    public async Task BySpecialization_BreaksPublishedAtTies_ById_Deterministically()
    {
        var first = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var second = Guid.Parse("00000000-0000-0000-0000-000000000002");

        // Ekleme sırası Id sırasının tersi.
        await AddNewsAsync("İkinci", T0, new[] { "C#" }, id: second);
        await AddNewsAsync("Birinci", T0, new[] { "C#" }, id: first);
        await AddNewsAsync("Daha yeni", T0.AddHours(1), new[] { "C#" });

        var run1 = await BySpecializationAsync("Backend");
        var run2 = await BySpecializationAsync("Backend");

        Assert.Equal(new[] { "Daha yeni", "Birinci", "İkinci" }, run1.Select(n => n.Title));
        Assert.Equal(run1.Select(n => n.Id), run2.Select(n => n.Id));
    }

    [Fact]
    public async Task ByProfession_ReturnsNewsOfAllSpecializationsInProfession_Only()
    {
        await AddNewsAsync("C# haberi", T0, new[] { "C#" });                 // Yazılım/Backend
        await AddNewsAsync("Flutter haberi", T0.AddDays(1), new[] { "Flutter" }); // Yazılım/Mobile
        await AddNewsAsync("Linux haberi", T0.AddDays(2), new[] { "Linux" });     // Siber Güvenlik

        await using var db = CreateContext();
        var software = await new NewsRepository(db).GetActiveByProfessionAsync(
            await ProfessionIdAsync("Yazılım Geliştirici"), 10);

        Assert.Equal(new[] { "Flutter haberi", "C# haberi" }, software.Select(n => n.Title));
    }
}
