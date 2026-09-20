using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Menzilim.Domain;

namespace Menzilim.Infrastructure.Data.Seed;

/// <summary>
/// Living Project şablonlarını (LearningPath + LearningItem) seed eder.
/// Idempotenttir: şablonlar uzmanlık + başlık, adımlar sıra numarasıyla eşlenir.
/// Şimdilik yalnızca "Yazılım Geliştirici" mesleği kapsanır.
/// </summary>
public static class ProjectSeeder
{
    public sealed record StepDefinition(
        string Title,
        string Description,
        int EstimatedMinutes,
        string? ContentTitle,
        string? SkillName);

    public sealed record ProjectDefinition(
        string SpecializationName,
        string Title,
        string Description,
        string Level,
        StepDefinition[] Steps);

    public static readonly IReadOnlyList<ProjectDefinition> Projects = new[]
    {
        new ProjectDefinition(
            "Frontend",
            "Modern Web Arayüzü",
            "Bu yolun sonunda tarayıcıda çalışan, etkileşimli ve yayına hazır bir web arayüzü geliştirmiş olacaksın.",
            "Beginner",
            new[]
            {
                new StepDefinition(
                    "Proje fikrini ve ekranları belirle",
                    "Arayüzün hangi ekranlardan oluşacağını ve her ekranda ne göstereceğini kısa notlarla yaz.",
                    20,
                    null,
                    null),
                new StepDefinition(
                    "Sayfa iskeletini HTML ile kur",
                    "Anlamsal HTML etiketleriyle sayfanın yapısını oluştur: başlık, içerik alanı, form ve liste.",
                    45,
                    "Learn HTML",
                    "HTML ve CSS"),
                new StepDefinition(
                    "Arayüzü CSS ile biçimlendir",
                    "Renk, tipografi ve yerleşimi düzenle; sayfanın dar ekranda da okunabilir olmasını sağla.",
                    40,
                    "Learn HTML",
                    "HTML ve CSS"),
                new StepDefinition(
                    "JavaScript ile etkileşim ekle",
                    "Form gönderimi, liste ekleme/silme gibi kullanıcı etkileşimlerini JavaScript ile çalıştır.",
                    60,
                    "JavaScript Guide",
                    "JavaScript"),
                new StepDefinition(
                    "Arayüzü bileşenlere ayır",
                    "Tekrar eden parçaları React bileşenlerine dönüştür ve durumu (state) tek yerden yönet.",
                    30,
                    "React Quick Start",
                    "React"),
                new StepDefinition(
                    "Tip güvenliği ekle",
                    "TypeScript ile veri tiplerini tanımla; hataları çalışma zamanından önce yakala.",
                    50,
                    "TypeScript Handbook",
                    "TypeScript"),
                new StepDefinition(
                    "Projeyi yayına hazırla",
                    "Kodu sürüm kontrolüne al, README yaz ve projeyi portfolyona ekleyecek şekilde yayınla.",
                    30,
                    null,
                    "Git ve Versiyon Kontrolü"),
            }),

        new ProjectDefinition(
            "Backend",
            "REST API + Veritabanı Uygulaması",
            "Bu yolun sonunda veritabanına bağlı, kimlik doğrulamalı ve yayına hazır bir REST API geliştirmiş olacaksın.",
            "Beginner",
            new[]
            {
                new StepDefinition(
                    "Proje gereksinimlerini ve veri modelini belirle",
                    "API'nin hangi kaynakları yöneteceğini ve bu kaynakların alanlarını yaz.",
                    20,
                    null,
                    null),
                new StepDefinition(
                    "C# temellerini tazele",
                    "Tipler, sınıflar ve async/await gibi API geliştirirken sürekli kullanacağın kavramları gözden geçir.",
                    40,
                    "A tour of the C# language",
                    "C#"),
                new StepDefinition(
                    "İlk uç noktayı oluştur",
                    "Minimal API ile çalışan bir GET uç noktası yaz ve yanıtını tarayıcıdan doğrula.",
                    35,
                    "Create a minimal API with ASP.NET Core",
                    "ASP.NET Core"),
                new StepDefinition(
                    "Veritabanı şemasını tasarla",
                    "Tabloları, ilişkileri ve anahtarları belirle; temel sorguları SQL ile dene.",
                    60,
                    "SQL Tutorial",
                    "SQL"),
                new StepDefinition(
                    "Veri erişimini EF Core ile kur",
                    "DbContext ve modelleri oluştur, migration üret ve veritabanını güncelle.",
                    45,
                    "Getting Started with EF Core",
                    "Entity Framework Core"),
                new StepDefinition(
                    "CRUD uç noktalarını tamamla",
                    "Listeleme, ekleme, güncelleme ve silme uç noktalarını yazıp uçtan uca test et.",
                    50,
                    "ASP.NET Core Web API Development",
                    "REST API"),
                new StepDefinition(
                    "API tasarımını ve hataları standartlaştır",
                    "URL tasarımı, durum kodları ve hata yanıtlarını tutarlı hale getir.",
                    40,
                    "Web API design best practices",
                    "REST API"),
                new StepDefinition(
                    "Projeyi yayına hazırla",
                    "Kodu sürüm kontrolüne al, README ve örnek istekleri yaz, projeyi portfolyona ekle.",
                    30,
                    null,
                    "Git ve Versiyon Kontrolü"),
            }),

        new ProjectDefinition(
            "Full Stack",
            "Görev Takip Uygulaması",
            "Bu yolun sonunda arayüzü, API'si ve veritabanı olan uçtan uca çalışan bir görev takip uygulaması geliştirmiş olacaksın.",
            "Beginner",
            new[]
            {
                new StepDefinition(
                    "Proje gereksinimlerini belirle",
                    "Uygulamanın hangi görevleri çözeceğini ve ekranlarını kısa bir listeyle netleştir.",
                    20,
                    null,
                    null),
                new StepDefinition(
                    "Arayüzü oluştur",
                    "Görev listesi ve görev ekleme formunu HTML ile kur.",
                    45,
                    "Learn HTML",
                    "HTML ve CSS"),
                new StepDefinition(
                    "Arayüze etkileşim ekle",
                    "Görev ekleme, tamamlama ve silme işlemlerini JavaScript ile çalıştır.",
                    60,
                    "JavaScript Guide",
                    "JavaScript"),
                new StepDefinition(
                    "Veritabanını tasarla",
                    "Görev ve kullanıcı tablolarını, ilişkilerini ve temel sorgularını hazırla.",
                    60,
                    "SQL Tutorial",
                    "SQL"),
                new StepDefinition(
                    "API'yi geliştir",
                    "Görevleri okuyan ve yazan uç noktaları Minimal API ile oluştur.",
                    35,
                    "Create a minimal API with ASP.NET Core",
                    "ASP.NET Core"),
                new StepDefinition(
                    "Veri erişimini bağla",
                    "EF Core ile API'yi veritabanına bağla ve verinin kalıcı olduğunu doğrula.",
                    45,
                    "Getting Started with EF Core",
                    "Entity Framework Core"),
                new StepDefinition(
                    "Kullanıcı işlemleri ve güvenliği ekle",
                    "Kayıt/giriş akışını ekle; parola saklama ve yetkilendirme kurallarını güvenli kur.",
                    40,
                    "Web API design best practices",
                    "Web Uygulama Güvenliği"),
                new StepDefinition(
                    "Test et ve yayına hazırla",
                    "Temel akışları elle test et, README yaz ve projeyi portfolyona ekle.",
                    30,
                    null,
                    "Git ve Versiyon Kontrolü"),
            }),

        new ProjectDefinition(
            "Mobile",
            "Mobil Görev Takip Uygulaması",
            "Bu yolun sonunda telefonda çalışan, veri kaydeden ve yayına hazır bir mobil uygulama geliştirmiş olacaksın.",
            "Beginner",
            new[]
            {
                new StepDefinition(
                    "Uygulama akışını planla",
                    "Ekranları ve ekranlar arası geçişleri kısa bir akış şemasıyla belirle.",
                    20,
                    null,
                    null),
                new StepDefinition(
                    "Dart temellerini öğren",
                    "Değişkenler, null safety ve asenkron programlama ile Dart'ın temellerini çalış.",
                    40,
                    "Introduction to Dart",
                    "Dart"),
                new StepDefinition(
                    "İlk Flutter uygulamanı oluştur",
                    "Çalışan bir Flutter projesi kur ve ilk ekranı yayına al.",
                    60,
                    "Your first Flutter app",
                    "Flutter"),
                new StepDefinition(
                    "Ekran düzenlerini kur",
                    "Row, Column ve Stack ile görev listesi ekranının düzenini oluştur.",
                    30,
                    "Layouts in Flutter",
                    "Mobil Arayüz Tasarımı"),
                new StepDefinition(
                    "Görev listesi ve durum yönetimini ekle",
                    "Görev ekleme/tamamlama işlemlerini katmanlı bir yapıyla yönet.",
                    45,
                    "Guide to app architecture",
                    "Flutter"),
                new StepDefinition(
                    "Veriyi API ile bağla",
                    "Görevleri bir REST API üzerinden oku ve yaz; hata durumlarını ekranda göster.",
                    40,
                    "Web API design best practices",
                    "REST API"),
                new StepDefinition(
                    "Test et ve yayına hazırla",
                    "Uygulamayı cihazda dene, README yaz ve projeyi portfolyona ekle.",
                    30,
                    null,
                    "Git ve Versiyon Kontrolü"),
            }),
    };

    public static async Task SeedAsync(
        MenzilimDbContext db,
        ILogger? logger = null)
    {
        var warnings = new List<string>();

        var profession = await db.Professions
            .SingleOrDefaultAsync(
                p => p.Name == ContentSeeder.SoftwareProfessionName);

        if (profession is null)
        {
            logger?.LogWarning(
                "'{Profession}' mesleği bulunamadı; proje seed'i atlandı.",
                ContentSeeder.SoftwareProfessionName);

            return;
        }

        var specializations = await db.Specializations
            .Where(s => s.ProfessionId == profession.Id)
            .ToListAsync();

        var contentsByTitle = await db.Contents
            .ToDictionaryAsync(c => c.Title, c => c.Id);

        var skillsByName = await db.Skills
            .ToDictionaryAsync(s => s.Name, s => s.Id);

        foreach (var definition in Projects)
        {
            var specialization = specializations
                .SingleOrDefault(s => s.Name == definition.SpecializationName);

            if (specialization is null)
            {
                warnings.Add(
                    $"'{definition.SpecializationName}' uzmanlığı bulunamadı; " +
                    $"'{definition.Title}' projesi atlandı.");

                continue;
            }

            var path = await db.LearningPaths
                .Include(p => p.Items)
                .SingleOrDefaultAsync(p =>
                    p.SpecializationId == specialization.Id &&
                    p.Title == definition.Title);

            if (path is null)
            {
                path = new LearningPath
                {
                    Id = Guid.NewGuid(),
                    Title = definition.Title,
                    Description = definition.Description,
                    ProfessionId = profession.Id,
                    SpecializationId = specialization.Id,
                    Level = definition.Level,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };

                db.LearningPaths.Add(path);
            }
            else
            {
                // Metinler güncellenebilir; kullanıcı ilerlemesi adımlara bağlı
                // olduğu için mevcut Id korunur.
                path.Description = definition.Description;
                path.Level = definition.Level;
                path.IsActive = true;
            }

            for (var index = 0; index < definition.Steps.Length; index++)
            {
                var step = definition.Steps[index];
                var order = index + 1;

                Guid? contentId = null;
                if (step.ContentTitle is not null)
                {
                    if (contentsByTitle.TryGetValue(step.ContentTitle, out var foundContent))
                    {
                        contentId = foundContent;
                    }
                    else
                    {
                        warnings.Add(
                            $"'{step.ContentTitle}' içeriği bulunamadı; " +
                            $"'{step.Title}' adımı içeriksiz eklendi.");
                    }
                }

                Guid? skillId = null;
                if (step.SkillName is not null)
                {
                    if (skillsByName.TryGetValue(step.SkillName, out var foundSkill))
                    {
                        skillId = foundSkill;
                    }
                    else
                    {
                        warnings.Add(
                            $"'{step.SkillName}' becerisi bulunamadı; " +
                            $"'{step.Title}' adımı beceri ilişkisi olmadan eklendi.");
                    }
                }

                var item = path.Items.SingleOrDefault(i => i.Order == order);

                if (item is null)
                {
                    path.Items.Add(new LearningItem
                    {
                        Id = Guid.NewGuid(),
                        LearningPathId = path.Id,
                        Title = step.Title,
                        Description = step.Description,
                        Order = order,
                        EstimatedMinutes = step.EstimatedMinutes,
                        ContentId = contentId,
                        SkillId = skillId
                    });
                }
                else
                {
                    item.Title = step.Title;
                    item.Description = step.Description;
                    item.EstimatedMinutes = step.EstimatedMinutes;
                    item.ContentId = contentId;
                    item.SkillId = skillId;
                }
            }
        }

        await db.SaveChangesAsync();

        foreach (var warning in warnings)
        {
            logger?.LogWarning("Proje seed: {Warning}", warning);
        }
    }
}
