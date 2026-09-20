using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Menzilim.Domain;

namespace Menzilim.Infrastructure.Data.Seed;

/// <summary>
/// MVP demosu için başlangıç öğrenme içeriklerini ve quiz'leri seed eder.
/// Idempotent: içerik ve quiz'ler başlıkla eşleştirilir; mevcut kayıtlar
/// yeniden oluşturulmaz, değiştirilmez veya silinmez. Yalnızca eksik
/// içerik, meslek/skill bağlantısı ve quiz eklenir. Skill'lere ihtiyaç
/// duyduğu için <see cref="DatabaseSeeder"/>'dan sonra çalışmalıdır.
/// </summary>
public static class ContentSeeder
{
    public const string SoftwareProfessionName = "Yazılım Geliştirici";

    public sealed record ContentDefinition(
        string Title,
        string Description,
        string Url,
        string Source,
        string Level,
        int ReadingTimeMinutes,
        DateTime PublishedAt,
        string[] SkillNames);

    public sealed record QuestionDefinition(
        string Text,
        string OptionA,
        string OptionB,
        string OptionC,
        string OptionD,
        string CorrectOption,
        string? Explanation = null);

    public sealed record QuizDefinition(
        string Title,
        string Description,
        string SkillName,
        QuestionDefinition[] Questions);

    // Açıklamadaki "Önerilen uzmanlık" ifadesi, günlük plan seçicisinin
    // uzmanlık adı eşleşmesini (başlık/açıklama) besler. Seçici eşitlikte en
    // yeni PublishedAt'i önce aldığı için tarihler öğrenme sırasını yansıtır:
    // her uzmanlıkta temel içerik en yeni tarihlidir.
    public static readonly IReadOnlyList<ContentDefinition> Contents = new[]
    {
        // Frontend
        new ContentDefinition(
            "Learn HTML",
            "Anlamsal HTML, formlar, bağlantılar ve erişilebilirlik temelleriyle web sayfasının iskeletini kur. Önerilen uzmanlık: Frontend.",
            "https://web.dev/learn/html",
            "web.dev",
            "Beginner",
            45,
            new DateTime(2026, 9, 11, 0, 0, 0, DateTimeKind.Utc),
            new[] { "HTML ve CSS" }),

        new ContentDefinition(
            "JavaScript Guide",
            "Değişkenler, fonksiyonlar, nesneler ve asenkron programlama ile JavaScript'in temel kavramları. Önerilen uzmanlık: Frontend, Full Stack.",
            "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide",
            "MDN Web Docs",
            "Beginner",
            60,
            new DateTime(2026, 9, 10, 0, 0, 0, DateTimeKind.Utc),
            new[] { "JavaScript" }),

        new ContentDefinition(
            "TypeScript Handbook",
            "Tipler, arayüzler ve generic'lerle tip güvenli JavaScript yazmayı öğren. Önerilen uzmanlık: Frontend, Full Stack.",
            "https://www.typescriptlang.org/docs/handbook/intro.html",
            "TypeScript",
            "Intermediate",
            50,
            new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc),
            new[] { "TypeScript" }),

        new ContentDefinition(
            "Learn Angular",
            "TypeScript tabanlı Angular ile bileşen, şablon ve veri bağlama temellerini uygulamalı öğren. Önerilen uzmanlık: Frontend.",
            "https://angular.dev/tutorials/learn-angular",
            "Angular",
            "Intermediate",
            60,
            new DateTime(2026, 9, 7, 0, 0, 0, DateTimeKind.Utc),
            new[] { "TypeScript" }),

        new ContentDefinition(
            "React Quick Start",
            "Bileşenler, props, state ve olay yönetimiyle React'in temel kavramları. Önerilen uzmanlık: Frontend, Full Stack.",
            "https://react.dev/learn",
            "React",
            "Beginner",
            30,
            new DateTime(2026, 9, 8, 0, 0, 0, DateTimeKind.Utc),
            new[] { "React" }),

        // Backend
        new ContentDefinition(
            "A tour of the C# language",
            "Tipler, sınıflar, LINQ ve async/await ile C# dilinin genel turu. Önerilen uzmanlık: Backend.",
            "https://learn.microsoft.com/dotnet/csharp/tour-of-csharp/",
            "Microsoft Learn",
            "Beginner",
            40,
            new DateTime(2026, 9, 6, 0, 0, 0, DateTimeKind.Utc),
            new[] { "C#" }),

        // Mevcut veritabanlarında elle eklenmiş olabilir; aynı başlık
        // kullanıldığı için tekrar oluşturulmaz.
        new ContentDefinition(
            "ASP.NET Core Web API Development",
            "ASP.NET Core ile controller tabanlı Web API oluşturmanın temelleri. Önerilen uzmanlık: Backend, Full Stack.",
            "https://learn.microsoft.com/aspnet/core/web-api/",
            "Microsoft Learn",
            "Beginner",
            10,
            new DateTime(2026, 9, 3, 0, 0, 0, DateTimeKind.Utc),
            new[] { "ASP.NET Core" }),

        new ContentDefinition(
            "Getting Started with EF Core",
            "İlk EF Core uygulamanı oluştur: DbContext, model, migration ve temel CRUD işlemleri. Önerilen uzmanlık: Backend.",
            "https://learn.microsoft.com/ef/core/get-started/overview/first-app",
            "Microsoft Learn",
            "Beginner",
            30,
            new DateTime(2026, 9, 4, 0, 0, 0, DateTimeKind.Utc),
            new[] { "Entity Framework Core" }),

        new ContentDefinition(
            "SQL Tutorial",
            "SELECT, WHERE, JOIN, GROUP BY ve alt sorgularla ilişkisel veritabanı sorgulama. Önerilen uzmanlık: Backend, Full Stack.",
            "https://www.w3schools.com/sql/",
            "W3Schools",
            "Beginner",
            60,
            new DateTime(2026, 9, 5, 0, 0, 0, DateTimeKind.Utc),
            new[] { "SQL" }),

        // Full Stack
        new ContentDefinition(
            "Web API design best practices",
            "Kaynak odaklı URL tasarımı, HTTP metotları, durum kodları, sayfalama ve sürümleme ile RESTful API tasarımı. Önerilen uzmanlık: Full Stack, Backend.",
            "https://learn.microsoft.com/azure/architecture/best-practices/api-design",
            "Microsoft Learn",
            "Intermediate",
            35,
            new DateTime(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc),
            new[] { "REST API" }),

        new ContentDefinition(
            "Create a minimal API with ASP.NET Core",
            "Minimal API ile uçtan uca küçük bir servis kur ve bir istemciden tüket. Önerilen uzmanlık: Full Stack.",
            "https://learn.microsoft.com/aspnet/core/tutorials/min-web-api",
            "Microsoft Learn",
            "Beginner",
            45,
            new DateTime(2026, 9, 2, 0, 0, 0, DateTimeKind.Utc),
            new[] { "ASP.NET Core", "REST API" }),

        // Mobile
        new ContentDefinition(
            "Introduction to Dart",
            "Değişkenler, null safety, sınıflar ve asenkron programlamayla Dart diline giriş. Önerilen uzmanlık: Mobile.",
            "https://dart.dev/language",
            "Dart",
            "Beginner",
            40,
            new DateTime(2026, 9, 15, 0, 0, 0, DateTimeKind.Utc),
            new[] { "Dart" }),

        new ContentDefinition(
            "Your first Flutter app",
            "Adım adım ilk Flutter uygulamanı geliştir: widget'lar, durum yönetimi ve düzen. Önerilen uzmanlık: Mobile.",
            "https://codelabs.developers.google.com/codelabs/flutter-codelab-first",
            "Google Codelabs",
            "Beginner",
            60,
            new DateTime(2026, 9, 14, 0, 0, 0, DateTimeKind.Utc),
            new[] { "Flutter" }),

        new ContentDefinition(
            "Layouts in Flutter",
            "Row, Column, Stack ve kısıtlarla mobil ekran düzenleri oluşturma. Önerilen uzmanlık: Mobile.",
            "https://docs.flutter.dev/ui/layout",
            "Flutter",
            "Beginner",
            30,
            new DateTime(2026, 9, 13, 0, 0, 0, DateTimeKind.Utc),
            new[] { "Mobil Arayüz Tasarımı" }),

        new ContentDefinition(
            "Guide to app architecture",
            "Katmanlı mimari, view model ve repository desenleriyle ölçeklenebilir Flutter uygulaması tasarlama. Önerilen uzmanlık: Mobile.",
            "https://docs.flutter.dev/app-architecture",
            "Flutter",
            "Intermediate",
            45,
            new DateTime(2026, 9, 12, 0, 0, 0, DateTimeKind.Utc),
            new[] { "Flutter" }),
    };

    // Mevcut "ASP.NET Core Temelleri" quiz'i DatabaseSeeder'dadır; burada
    // yalnızca ek quiz'ler tanımlanır.
    public static readonly IReadOnlyList<QuizDefinition> Quizzes = new[]
    {
        new QuizDefinition(
            "JavaScript ve Web Temelleri",
            "Frontend: JavaScript, CSS düzeni ve TypeScript temelleri.",
            "JavaScript",
            new[]
            {
                new QuestionDefinition(
                    "JavaScript'te 'let' ile tanımlanan bir değişkenin kapsamı nedir?",
                    "Fonksiyon kapsamı; tanımlandığı fonksiyonun her yerinden erişilir.",
                    "Blok kapsamı; yalnızca tanımlandığı { } bloğu içinde geçerlidir.",
                    "Her zaman global kapsamdadır.",
                    "Yalnızca modül dışından erişilebilen bir sabittir.",
                    "B",
                    "let, tanımlandığı { } bloğuyla sınırlıdır. var ise fonksiyon kapsamlıdır; bu fark özellikle döngülerde hata kaynağı olur."),
                new QuestionDefinition(
                    "JavaScript'te '===' operatörü ne yapar?",
                    "Değeri atar.",
                    "Yalnızca tipleri karşılaştırır.",
                    "Hem değeri hem tipi, tip dönüşümü yapmadan karşılaştırır.",
                    "Tip dönüşümü yaptıktan sonra değerleri karşılaştırır.",
                    "C",
                    "=== tip dönüşümü yapmadan karşılaştırır. == ise tipleri dönüştürür, bu yüzden '1' == 1 doğru döner."),
                new QuestionDefinition(
                    "CSS'te bir kapsayıcıda Flexbox düzeni hangi bildirimle başlatılır?",
                    "position: flex;",
                    "float: flex;",
                    "layout: flexbox;",
                    "display: flex;",
                    "D",
                    "Flexbox kapsayıcıya display: flex verilerek başlatılır; hizalama sonra justify-content ve align-items ile yapılır."),
                new QuestionDefinition(
                    "TypeScript kodu tarayıcıda nasıl çalıştırılır?",
                    "JavaScript'e derlenir (transpile edilir) ve JavaScript olarak çalışır.",
                    "Tarayıcılar TypeScript'i doğrudan yorumlar.",
                    "WebAssembly'ye derlenmesi zorunludur.",
                    "Yalnızca sunucu tarafında çalıştırılabilir.",
                    "A",
                    "TypeScript tarayıcıda doğrudan çalışmaz; tsc ile JavaScript'e derlenir ve tipler derleme sonunda kaybolur."),
            }),

        new QuizDefinition(
            "Entity Framework Core ve SQL Temelleri",
            "Backend: EF Core ile veri erişimi ve temel SQL sorguları.",
            "Entity Framework Core",
            new[]
            {
                new QuestionDefinition(
                    "EF Core'da DbContext'in temel görevi nedir?",
                    "HTTP isteklerini yönlendirmek.",
                    "Veritabanıyla bir oturumu temsil edip sorgulama ve değişiklikleri kaydetmeyi sağlamak.",
                    "Kullanıcı arayüzü bileşenlerini oluşturmak.",
                    "JWT token üretmek.",
                    "B",
                    "DbContext veritabanı oturumunu temsil eder: sorgular onun üzerinden yazılır, değişiklikler SaveChanges ile kaydedilir."),
                new QuestionDefinition(
                    "EF Core'da model değişikliklerini veritabanı şemasına kontrollü biçimde uygulamak için ne kullanılır?",
                    "Migrations",
                    "Middleware",
                    "Razor Pages",
                    "SignalR",
                    "A",
                    "Migration'lar model değişikliğini sürümlenebilir adımlara çevirir; şema böylece kontrollü ve geri alınabilir şekilde güncellenir."),
                new QuestionDefinition(
                    "SQL'de GROUP BY ile gruplanmış sonuçları bir koşula göre filtrelemek için hangi ifade kullanılır?",
                    "WHERE",
                    "ORDER BY",
                    "HAVING",
                    "DISTINCT",
                    "C",
                    "WHERE gruplamadan önce satırları, HAVING gruplamadan sonra grupları filtreler. COUNT gibi toplamalarla HAVING kullanılır."),
                new QuestionDefinition(
                    "İki tablodan yalnızca her iki tabloda eşleşen satırları getiren JOIN türü hangisidir?",
                    "LEFT JOIN",
                    "FULL OUTER JOIN",
                    "CROSS JOIN",
                    "INNER JOIN",
                    "D",
                    "INNER JOIN yalnızca iki tarafta eşleşen satırları getirir; LEFT JOIN soldaki tüm satırları korur."),
            }),

        new QuizDefinition(
            "REST API Temelleri",
            "Full Stack: HTTP metotları, durum kodları ve REST tasarım ilkeleri.",
            "REST API",
            new[]
            {
                new QuestionDefinition(
                    "REST'te yeni bir kaynak oluşturmak için genellikle hangi HTTP metodu kullanılır?",
                    "GET",
                    "POST",
                    "DELETE",
                    "HEAD",
                    "B",
                    "Yeni kaynak POST ile oluşturulur. PUT belirli bir adrese yazar veya günceller, GET ise veriyi değiştirmez."),
                new QuestionDefinition(
                    "Bir kaynak başarıyla oluşturulduğunda dönülmesi önerilen HTTP durum kodu hangisidir?",
                    "201 Created",
                    "200 OK",
                    "204 No Content",
                    "302 Found",
                    "A",
                    "201 Created kaynağın oluştuğunu belirtir ve genellikle Location başlığıyla yeni kaynağın adresini döner."),
                new QuestionDefinition(
                    "İstenen kaynak bulunamadığında hangi HTTP durum kodu dönülür?",
                    "400 Bad Request",
                    "401 Unauthorized",
                    "404 Not Found",
                    "500 Internal Server Error",
                    "C",
                    "404 kaynağın bulunamadığını söyler. 400 isteğin hatalı, 401 ise kimliğin doğrulanmamış olduğunu belirtir."),
                new QuestionDefinition(
                    "Aşağıdaki HTTP metotlarından hangisi idempotent'tir (aynı istek tekrarlandığında sonuç değişmez)?",
                    "POST",
                    "Hiçbiri",
                    "Yalnızca POST ve PATCH",
                    "PUT",
                    "D",
                    "PUT aynı veriyle tekrarlandığında sonuç değişmez; POST ise her çağrıda yeni bir kaynak oluşturabilir."),
            }),

        new QuizDefinition(
            "Flutter ve Dart Temelleri",
            "Mobile: Flutter widget'ları, durum yönetimi ve Dart dili temelleri.",
            "Flutter",
            new[]
            {
                new QuestionDefinition(
                    "Flutter'da kendi değişken durumu olmayan bir arayüz parçası için hangi widget türü kullanılır?",
                    "StatelessWidget",
                    "StatefulWidget",
                    "InheritedWidget",
                    "RenderObject",
                    "A",
                    "Kendi değişen durumu olmayan parçalar StatelessWidget'tır; veri yalnızca dışarıdan parametreyle gelir."),
                new QuestionDefinition(
                    "StatefulWidget içinde durum değiştiğinde arayüzün yeniden çizilmesi için hangi metot çağrılır?",
                    "initState()",
                    "dispose()",
                    "setState()",
                    "build() doğrudan çağrılır",
                    "C",
                    "setState değişikliği çerçeveye bildirir ve build'in yeniden çalışmasını sağlar; build doğrudan çağrılmaz."),
                new QuestionDefinition(
                    "Dart'ta 'final' ile 'const' arasındaki fark nedir?",
                    "İkisi tamamen aynıdır.",
                    "'const' derleme zamanında bilinen bir sabittir; 'final' çalışma zamanında yalnızca bir kez atanabilir.",
                    "'final' derleme zamanı sabitidir; 'const' birden fazla kez atanabilir.",
                    "'const' yalnızca sınıf alanlarında kullanılabilir.",
                    "B",
                    "const değer derleme zamanında bilinir; final ise çalışma zamanında bir kez atanır (ör. DateTime.now())."),
                new QuestionDefinition(
                    "Flutter'da alt widget'ları dikey olarak alt alta dizen widget hangisidir?",
                    "Row",
                    "Stack",
                    "Wrap",
                    "Column",
                    "D",
                    "Column çocukları dikey, Row yatay dizer; Stack ise üst üste yerleştirir."),
            }),
    };

    /// <returns>
    /// Uygulanamayan adımlar için uyarılar (meslek/skill yok, belirsiz başlık
    /// vb.). Bu durumlarda tahminle eşleştirme yapılmaz.
    /// </returns>
    public static async Task<IReadOnlyList<string>> SeedAsync(
        MenzilimDbContext db,
        ILogger? logger = null)
    {
        var warnings = new List<string>();

        // SQL Server varsayılan collation'ı büyük/küçük harf duyarsız; eşleşme
        // de duyarsız yapılır.
        var skillsByName = (await db.Skills.ToListAsync())
            .ToDictionary(s => s.Name, StringComparer.OrdinalIgnoreCase);

        var profession = await db.Professions
            .SingleOrDefaultAsync(p => p.Name == SoftwareProfessionName);

        if (profession is null)
        {
            warnings.Add(
                $"'{SoftwareProfessionName}' mesleği bulunamadı; içerik seed'i atlandı.");
        }
        else
        {
            await SeedContentsAsync(db, profession, skillsByName, warnings);
        }

        await SeedQuizzesAsync(db, skillsByName, warnings);

        await db.SaveChangesAsync();

        foreach (var warning in warnings)
        {
            logger?.LogWarning("Content seed: {Warning}", warning);
        }

        return warnings;
    }

    private static async Task SeedContentsAsync(
        MenzilimDbContext db,
        Profession profession,
        IReadOnlyDictionary<string, Skill> skillsByName,
        List<string> warnings)
    {
        var contentsByTitle = (await db.Contents.ToListAsync())
            .GroupBy(c => c.Title, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.ToList(), StringComparer.OrdinalIgnoreCase);

        var professionLinks = (await db.ContentProfessions
                .Select(cp => new { cp.ContentId, cp.ProfessionId })
                .ToListAsync())
            .Select(l => (l.ContentId, l.ProfessionId))
            .ToHashSet();

        var skillLinks = (await db.ContentSkills
                .Select(cs => new { cs.ContentId, cs.SkillId })
                .ToListAsync())
            .Select(l => (l.ContentId, l.SkillId))
            .ToHashSet();

        foreach (var definition in Contents)
        {
            Content content;

            if (!contentsByTitle.TryGetValue(definition.Title, out var existing))
            {
                content = new Content
                {
                    Id = Guid.NewGuid(),
                    Title = definition.Title,
                    Description = definition.Description,
                    Url = definition.Url,
                    Source = definition.Source,
                    PublishedAt = definition.PublishedAt,
                    ReadingTimeMinutes = definition.ReadingTimeMinutes,
                    Level = definition.Level,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                };

                db.Contents.Add(content);
            }
            else if (existing.Count == 1)
            {
                // Mevcut içerik değiştirilmez; yalnızca eksik bağlantıları tamamlanır.
                content = existing[0];
            }
            else
            {
                warnings.Add(
                    $"'{definition.Title}' başlıklı {existing.Count} içerik var; bağlantılar belirsiz olduğu için atlandı.");
                continue;
            }

            if (professionLinks.Add((content.Id, profession.Id)))
            {
                db.ContentProfessions.Add(new ContentProfession
                {
                    Id = Guid.NewGuid(),
                    ContentId = content.Id,
                    ProfessionId = profession.Id,
                });
            }

            foreach (var skillName in definition.SkillNames)
            {
                if (!skillsByName.TryGetValue(skillName, out var skill))
                {
                    warnings.Add(
                        $"'{skillName}' skill'i bulunamadı; '{definition.Title}' eşleştirmesi atlandı.");
                    continue;
                }

                if (!skillLinks.Add((content.Id, skill.Id)))
                {
                    continue;
                }

                db.ContentSkills.Add(new ContentSkill
                {
                    Id = Guid.NewGuid(),
                    ContentId = content.Id,
                    SkillId = skill.Id,
                });
            }
        }
    }

    private static async Task SeedQuizzesAsync(
        MenzilimDbContext db,
        IReadOnlyDictionary<string, Skill> skillsByName,
        List<string> warnings)
    {
        var existingTitles = (await db.Quizzes
                .Select(q => q.Title)
                .ToListAsync())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var definition in Quizzes)
        {
            // Mevcut quiz (ve soruları) değiştirilmez; yalnızca eksik
            // açıklamalar tamamlanır.
            if (existingTitles.Contains(definition.Title))
            {
                await BackfillExplanationsAsync(db, definition);
                continue;
            }

            if (!skillsByName.TryGetValue(definition.SkillName, out var skill))
            {
                warnings.Add(
                    $"'{definition.SkillName}' skill'i bulunamadı; '{definition.Title}' quiz'i skill bağlantısı olmadan eklendi.");
            }

            var quiz = new Quiz
            {
                Id = Guid.NewGuid(),
                Title = definition.Title,
                Description = definition.Description,
                SkillId = skill?.Id,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
            };

            foreach (var question in definition.Questions)
            {
                quiz.Questions.Add(new Question
                {
                    Id = Guid.NewGuid(),
                    QuizId = quiz.Id,
                    Text = question.Text,
                    OptionA = question.OptionA,
                    OptionB = question.OptionB,
                    OptionC = question.OptionC,
                    OptionD = question.OptionD,
                    CorrectOption = question.CorrectOption,
                    Explanation = question.Explanation,
                });
            }

            db.Quizzes.Add(quiz);
            existingTitles.Add(quiz.Title);
        }
    }

    /// <summary>
    /// Daha önce seed edilmiş quiz'lerin sorularına eksik açıklamaları yazar.
    /// Mevcut açıklamalara dokunmaz.
    /// </summary>
    private static async Task BackfillExplanationsAsync(
        MenzilimDbContext db,
        QuizDefinition definition)
    {
        var explanations = definition.Questions
            .Where(q => !string.IsNullOrWhiteSpace(q.Explanation))
            .ToDictionary(
                q => q.Text,
                q => q.Explanation!,
                StringComparer.OrdinalIgnoreCase);

        if (explanations.Count == 0)
        {
            return;
        }

        var questions = await db.Questions
            .Where(q => q.Quiz.Title == definition.Title)
            .Where(q => q.Explanation == null)
            .ToListAsync();

        foreach (var question in questions)
        {
            if (explanations.TryGetValue(question.Text, out var explanation))
            {
                question.Explanation = explanation;
            }
        }
    }
}
