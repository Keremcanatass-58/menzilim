using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Menzilim.Domain;

namespace Menzilim.Infrastructure.Data.Seed;

/// <summary>
/// Haber akışı V1 için başlangıç haberlerini seed eder. Yalnızca resmi
/// duyuru/sürüm kaynakları kullanılır; özetler kaynak sayfadaki bilgilere
/// dayanır, haberin tamamı saklanmaz.
/// Idempotent: haberler SourceUrl ile eşleştirilir; mevcut kayıtlar yeniden
/// oluşturulmaz veya değiştirilmez, yalnızca eksik haber ve skill bağlantısı
/// eklenir. Skill'lere ihtiyaç duyduğu için <see cref="DatabaseSeeder"/>'dan
/// sonra çalışmalıdır.
/// </summary>
public static class NewsSeeder
{
    public sealed record NewsDefinition(
        string Title,
        string Summary,
        string SourceName,
        string SourceUrl,
        DateTime PublishedAt,
        string[] SkillNames);

    private static DateTime Utc(int year, int month, int day, int hour = 0, int minute = 0) =>
        new(year, month, day, hour, minute, 0, DateTimeKind.Utc);

    // PublishedAt: kaynak sayfadaki yayın tarihi. Microsoft Learn sürüm notları
    // .NET 10 duyurusundan bağlantılı olduğundan .NET 10'un yayın tarihini alır.
    public static readonly IReadOnlyList<NewsDefinition> News = new[]
    {
        // .NET / Backend
        new NewsDefinition(
            ".NET 10 yayınlandı: yeni LTS sürümü",
            ".NET 10, 10 Kasım 2028'e kadar desteklenecek bir Long Term Support (LTS) sürümü olarak yayınlandı. ASP.NET Core, C# 14, .NET MAUI ve Aspire tarafında güncellemeler içeriyor.",
            ".NET Blog",
            "https://devblogs.microsoft.com/dotnet/announcing-dotnet-10/",
            Utc(2025, 11, 11, 15, 38),
            new[] { "C#", "ASP.NET Core" }),

        new NewsDefinition(
            "C# 14 tanıtıldı: extension members ve daha fazlası",
            ".NET 10 ile gelen C# 14'ün öne çıkan özelliği yeni extension members söz dizimi. field anahtar sözcüğü, null-conditional atama ve partial constructor/event desteği de geliyor.",
            ".NET Blog",
            "https://devblogs.microsoft.com/dotnet/introducing-csharp-14/",
            Utc(2025, 11, 17, 18, 5),
            new[] { "C#" }),

        new NewsDefinition(
            "ASP.NET Core'da .NET 10 yenilikleri",
            "ASP.NET Core'un .NET 10 sürüm notları: OpenAPI 3.1 desteği, ASP.NET Core Identity için passkey (WebAuthn) desteği, Minimal API ve Blazor iyileştirmeleri.",
            "Microsoft Learn",
            "https://learn.microsoft.com/aspnet/core/release-notes/aspnetcore-10.0",
            Utc(2025, 11, 11, 15, 38),
            new[] { "ASP.NET Core" }),

        new NewsDefinition(
            "EF Core 10 yayınlandı",
            "Entity Framework Core 10, .NET 10 ile birlikte geldi: .NET 10'un LeftJoin/RightJoin operatörleri, SQL Server vector veri tipi desteği ve adlandırılmış (named) query filter'lar.",
            "Microsoft Learn",
            "https://learn.microsoft.com/ef/core/what-is-new/ef-core-10.0/whatsnew",
            Utc(2025, 11, 11, 15, 38),
            new[] { "Entity Framework Core" }),

        new NewsDefinition(
            "SQL Server 2025 önizlemesi duyuruldu",
            "Microsoft, SQL Server 2025'in genel önizlemesini duyurdu: veritabanı motoruna yerleşik vektör arama ve yerel JSON desteğiyle yapay zekâ uygulamalarına hazır kurumsal veritabanı.",
            "Microsoft SQL Server Blog",
            "https://www.microsoft.com/en-us/sql-server/blog/2025/05/19/announcing-sql-server-2025-preview-the-ai-ready-enterprise-database-from-ground-to-cloud/",
            Utc(2025, 5, 19, 16, 0),
            new[] { "SQL" }),

        // JavaScript / TypeScript / Frontend
        new NewsDefinition(
            "TypeScript 5.9 yayınlandı",
            "TypeScript 5.9; import defer desteği, --module node20 seçeneği, sadeleştirilmiş tsc --init ve editörde genişletilebilir hover önizlemesi getiriyor.",
            "TypeScript Blog",
            "https://devblogs.microsoft.com/typescript/announcing-typescript-5-9/",
            Utc(2025, 8, 1, 16, 19),
            new[] { "TypeScript" }),

        new NewsDefinition(
            "TypeScript derleyicisi native'e taşınıyor: 10 kat hız hedefi",
            "TypeScript ekibi, mevcut derleyiciyi ve araçlarını native koda taşıyarak yaklaşık 10 kat performans artışı hedefliyor.",
            "TypeScript Blog",
            "https://devblogs.microsoft.com/typescript/typescript-native-port/",
            Utc(2025, 3, 11, 14, 31),
            new[] { "TypeScript" }),

        new NewsDefinition(
            "React 19.2 yayınlandı",
            "React 19.2; <Activity /> bileşeni, useEffectEvent ve cacheSignal ile React DOM tarafında Partial Pre-rendering desteğini getiriyor.",
            "React Blog",
            "https://react.dev/blog/2025/10/01/react-19-2",
            Utc(2025, 10, 1),
            new[] { "React" }),

        new NewsDefinition(
            "React Compiler v1.0 kararlı sürümde",
            "Derleme zamanında otomatik memoization yapan React Compiler'ın ilk kararlı sürümü yayınlandı; React ve React Native'de çalışıyor, Expo, Vite ve Next.js ile yeni projelerde etkinleştirilebiliyor.",
            "React Blog",
            "https://react.dev/blog/2025/10/07/react-compiler-1",
            Utc(2025, 10, 7),
            new[] { "React" }),

        new NewsDefinition(
            "React 19 kararlı sürümü yayınlandı",
            "React 19 kararlı hale geldi: veri güncellemeleri için Actions, useActionState ve useOptimistic hook'ları ile Server Components.",
            "React Blog",
            "https://react.dev/blog/2024/12/05/react-19",
            Utc(2024, 12, 5),
            new[] { "React" }),

        new NewsDefinition(
            "Node.js 25 yayınlandı",
            "Node.js 25 (Current), V8 14.1 ile JSON.stringify performansında büyük iyileştirmeler getiriyor; Web Storage varsayılan olarak açık ve izin modeline --allow-net eklendi.",
            "Node.js Blog",
            "https://nodejs.org/en/blog/release/v25.0.0",
            Utc(2025, 10, 15),
            new[] { "JavaScript" }),

        new NewsDefinition(
            "Node.js 24 yayınlandı",
            "Node.js 24 (Current), V8 13.6 ve npm 11 ile geliyor; URLPattern global olarak kullanılabiliyor ve AsyncLocalStorage varsayılan olarak AsyncContextFrame kullanıyor.",
            "Node.js Blog",
            "https://nodejs.org/en/blog/release/v24.0.0",
            Utc(2025, 5, 6),
            new[] { "JavaScript" }),

        new NewsDefinition(
            "Chrome 140'ta web geliştiricileri için yenilikler",
            "Chrome 140; ToggleEvent source özelliği ve font-variation-settings tanımlayıcısı gibi HTML ve CSS yeniliklerini getiriyor.",
            "Chrome for Developers",
            "https://developer.chrome.com/blog/new-in-chrome-140",
            Utc(2025, 9, 2),
            new[] { "HTML ve CSS" }),

        // Mobile
        new NewsDefinition(
            "Flutter 3.32 yayınlandı",
            "Flutter 3.32; web'de hot reload, platformlara daha yakın (native fidelity) arayüz ve daha derin entegrasyonlar getiriyor.",
            "Flutter Blog",
            "https://flutter.dev/blog/whats-new-in-flutter-3-32",
            Utc(2025, 5, 20),
            new[] { "Flutter" }),

        new NewsDefinition(
            "Dart 3.8 duyuruldu",
            "Dart 3.8; formatter güncellemeleri, koleksiyonlar için null-aware elemanlar ve yeni çapraz platform geliştirme yetenekleri içeriyor.",
            "Dart Blog",
            "https://dart.dev/blog/announcing-dart-3-8",
            Utc(2025, 5, 20),
            new[] { "Dart" }),
    };

    /// <returns>
    /// Uygulanamayan adımlar için uyarılar (skill yok vb.). Bu durumlarda
    /// tahminle eşleştirme yapılmaz.
    /// </returns>
    public static async Task<IReadOnlyList<string>> SeedAsync(
        MenzilimDbContext db,
        ILogger? logger = null)
    {
        var warnings = new List<string>();

        // SQL Server varsayılan collation'ı büyük/küçük harf duyarsız; unique
        // index ile çakışmamak için eşleşme de duyarsız yapılır.
        var skillsByName = (await db.Skills.ToListAsync())
            .ToDictionary(s => s.Name, StringComparer.OrdinalIgnoreCase);

        var newsByUrl = (await db.NewsItems.ToListAsync())
            .ToDictionary(n => n.SourceUrl, StringComparer.OrdinalIgnoreCase);

        var skillLinks = (await db.NewsItemSkills
                .Select(ns => new { ns.NewsItemId, ns.SkillId })
                .ToListAsync())
            .Select(l => (l.NewsItemId, l.SkillId))
            .ToHashSet();

        foreach (var definition in News)
        {
            if (!newsByUrl.TryGetValue(definition.SourceUrl, out var news))
            {
                news = new NewsItem
                {
                    Id = Guid.NewGuid(),
                    Title = definition.Title,
                    Summary = definition.Summary,
                    SourceName = definition.SourceName,
                    SourceUrl = definition.SourceUrl,
                    PublishedAt = definition.PublishedAt,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                };

                db.NewsItems.Add(news);
                newsByUrl[news.SourceUrl] = news;
            }

            foreach (var skillName in definition.SkillNames)
            {
                if (!skillsByName.TryGetValue(skillName, out var skill))
                {
                    warnings.Add(
                        $"'{skillName}' skill'i bulunamadı; '{definition.Title}' eşleştirmesi atlandı.");
                    continue;
                }

                if (!skillLinks.Add((news.Id, skill.Id)))
                {
                    continue;
                }

                db.NewsItemSkills.Add(new NewsItemSkill
                {
                    Id = Guid.NewGuid(),
                    NewsItemId = news.Id,
                    SkillId = skill.Id,
                });
            }
        }

        await db.SaveChangesAsync();

        foreach (var warning in warnings)
        {
            logger?.LogWarning("News seed: {Warning}", warning);
        }

        return warnings;
    }
}
