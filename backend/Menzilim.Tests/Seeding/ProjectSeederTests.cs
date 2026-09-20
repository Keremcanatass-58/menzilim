using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Data.Seed;
using Xunit;

namespace Menzilim.Tests.Seeding;

/// <summary>
/// Living Project şablonlarının seed'ini gerçek bir ilişkisel veritabanında
/// (SQLite in-memory) çalıştırır ve idempotent olduğunu doğrular.
/// </summary>
public sealed class ProjectSeederTests : IDisposable
{
    private readonly SqliteConnection _connection;

    public ProjectSeederTests()
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

    // Uygulama açılışındaki sırayla: referans veriler, içerik, sonra projeler.
    private async Task SeedAllAsync()
    {
        await using var db = CreateContext();
        await DatabaseSeeder.SeedAsync(db);
        await ContentSeeder.SeedAsync(db);
        await ProjectSeeder.SeedAsync(db);
    }

    [Fact]
    public async Task Seed_CreatesOneProjectTemplatePerSoftwareSpecialization()
    {
        await SeedAllAsync();

        await using var db = CreateContext();

        var paths = await db.LearningPaths
            .Include(p => p.Items)
            .ToListAsync();

        Assert.Equal(ProjectSeeder.Projects.Count, paths.Count);

        foreach (var definition in ProjectSeeder.Projects)
        {
            var path = paths.Single(p => p.Title == definition.Title);

            Assert.Equal(definition.Steps.Length, path.Items.Count);
            Assert.InRange(path.Items.Count, 6, 8);
            Assert.True(path.IsActive);

            // Adımlar 1'den başlayarak kesintisiz sıralanır.
            Assert.Equal(
                Enumerable.Range(1, path.Items.Count),
                path.Items.Select(i => i.Order).OrderBy(o => o));
        }
    }

    [Fact]
    public async Task Seed_LinksStepsToRealContentAndSkills()
    {
        await SeedAllAsync();

        await using var db = CreateContext();

        var items = await db.LearningItems.ToListAsync();

        var expectedWithContent = ProjectSeeder.Projects
            .SelectMany(p => p.Steps)
            .Count(s => s.ContentTitle is not null);

        var expectedWithSkill = ProjectSeeder.Projects
            .SelectMany(p => p.Steps)
            .Count(s => s.SkillName is not null);

        // Tanımdaki tüm içerik ve beceri adları gerçekten eşleşmelidir.
        Assert.Equal(expectedWithContent, items.Count(i => i.ContentId is not null));
        Assert.Equal(expectedWithSkill, items.Count(i => i.SkillId is not null));
    }

    [Fact]
    public async Task Seed_IsIdempotent()
    {
        await SeedAllAsync();

        int pathCount, itemCount;
        await using (var db = CreateContext())
        {
            pathCount = await db.LearningPaths.CountAsync();
            itemCount = await db.LearningItems.CountAsync();
        }

        await SeedAllAsync();

        await using (var db = CreateContext())
        {
            Assert.Equal(pathCount, await db.LearningPaths.CountAsync());
            Assert.Equal(itemCount, await db.LearningItems.CountAsync());
        }
    }

    [Fact]
    public async Task Seed_MarksOnlyReadyProfessionsAsAvailable()
    {
        await SeedAllAsync();

        await using var db = CreateContext();

        var professions = await db.Professions.ToListAsync();

        var available = professions
            .Where(p => p.IsAvailable)
            .Select(p => p.Name)
            .ToList();

        Assert.Equal(
            new[] { ContentSeeder.SoftwareProfessionName },
            available);

        // Hazır olmayan meslekler silinmez, yalnızca seçilemez olur.
        Assert.Contains(professions, p => p.Name == "Siber Güvenlik");
        Assert.Contains(professions, p => p.Name == "Veri Uzmanı");
    }
}
