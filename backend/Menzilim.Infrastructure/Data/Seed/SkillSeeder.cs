using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Menzilim.Domain;

namespace Menzilim.Infrastructure.Data.Seed;

/// <summary>
/// Başlangıç skill kataloğunu ve uzmanlık-skill ilişkilerini seed eder.
/// Idempotent: yalnızca eksik skill ve ilişkileri ekler; mevcut kayıtları
/// değiştirmez veya silmez. Uygulama her açıldığında güvenle çalışabilir.
/// </summary>
public static class SkillSeeder
{
    public sealed record SkillDefinition(
        string Name,
        string Category,
        string Description);

    public static readonly IReadOnlyList<SkillDefinition> Skills = new[]
    {
        // Web / yazılım
        new SkillDefinition("HTML ve CSS", "Web", "Web sayfalarının yapısını ve görünümünü oluşturma."),
        new SkillDefinition("JavaScript", "Programlama", "Web için dinamik ve etkileşimli uygulamalar geliştirme."),
        new SkillDefinition("TypeScript", "Programlama", "Tip güvenli, ölçeklenebilir JavaScript geliştirme."),
        new SkillDefinition("React", "Web", "Bileşen tabanlı kullanıcı arayüzleri geliştirme."),
        new SkillDefinition("C#", "Programlama", ".NET ekosisteminde nesne yönelimli uygulama geliştirme."),
        new SkillDefinition("ASP.NET Core", "Web", "Modern, platformlar arası web uygulamaları ve API'ler geliştirme."),
        new SkillDefinition("REST API", "Web", "RESTful servis tasarlama ve istemci tarafında kullanma."),
        new SkillDefinition("SQL", "Veritabanı", "İlişkisel veritabanlarında sorgulama ve veri modelleme."),
        new SkillDefinition("Entity Framework Core", "Veritabanı", ".NET için ORM ile veri erişimi ve migration yönetimi."),
        new SkillDefinition("Git ve Versiyon Kontrolü", "Araçlar", "Kod değişikliklerini yönetme ve ekip içinde iş birliği."),

        // Mobil
        new SkillDefinition("Dart", "Programlama", "Flutter uygulamaları için Dart dili."),
        new SkillDefinition("Flutter", "Mobil", "Tek kod tabanıyla çok platformlu uygulama geliştirme."),
        new SkillDefinition("Mobil Arayüz Tasarımı", "Mobil", "Mobil cihazlara uygun, kullanılabilir arayüzler tasarlama."),

        // Güvenlik / ağ
        new SkillDefinition("Web Uygulama Güvenliği", "Güvenlik", "OWASP Top 10 ve güvenli yazılım geliştirme pratikleri."),
        new SkillDefinition("Ağ Temelleri", "Ağ", "TCP/IP, DNS, HTTP ve temel ağ protokolleri."),
        new SkillDefinition("Linux", "Sistem", "Linux komut satırı ve sistem yönetimi temelleri."),
        new SkillDefinition("SIEM ve Log Analizi", "Güvenlik", "Güvenlik olaylarını log verileri üzerinden izleme ve analiz etme."),
        new SkillDefinition("Olay Müdahalesi", "Güvenlik", "Güvenlik olaylarını tespit etme, sınırlandırma ve raporlama."),
        new SkillDefinition("Tehdit Tespiti", "Güvenlik", "MITRE ATT&CK ile saldırı tekniklerini tanıma ve tespit etme."),
        new SkillDefinition("Zafiyet Analizi", "Güvenlik", "Sistemlerdeki güvenlik açıklarını tarama ve önceliklendirme."),
        new SkillDefinition("Sızma Testi Metodolojisi", "Güvenlik", "Keşiften raporlamaya kadar yapılandırılmış sızma testi süreci."),
        new SkillDefinition("Güvenlik Duvarı ve IDS/IPS", "Ağ", "Ağ trafiğini filtreleme ve saldırı tespit/önleme sistemleri."),
        new SkillDefinition("Kriptografi Temelleri", "Güvenlik", "Şifreleme, hash ve TLS gibi temel kriptografi kavramları."),

        // Veri / yapay zeka
        new SkillDefinition("Python", "Programlama", "Veri analizi, otomasyon ve güvenlik araçları için Python."),
        new SkillDefinition("İstatistik", "Veri", "Tanımlayıcı istatistik, olasılık ve hipotez testleri."),
        new SkillDefinition("Veri Görselleştirme", "Veri", "Veriyi grafik ve panolarla anlaşılır biçimde sunma."),
        new SkillDefinition("Veri Temizleme ve Hazırlama", "Veri", "Eksik ve hatalı veriyi düzeltip analize hazırlama."),
        new SkillDefinition("Excel ve Tablolama", "Veri", "Tablolama araçlarıyla veri analizi ve raporlama."),
        new SkillDefinition("Makine Öğrenmesi", "Yapay Zeka", "Denetimli ve denetimsiz öğrenme algoritmaları."),
        new SkillDefinition("Doğrusal Cebir", "Yapay Zeka", "Vektör, matris ve makine öğrenmesinin matematiksel temelleri."),
        new SkillDefinition("Derin Öğrenme", "Yapay Zeka", "Yapay sinir ağları ve modern derin öğrenme mimarileri."),
        new SkillDefinition("MLOps ve Model Dağıtımı", "Yapay Zeka", "Modelleri üretime alma, izleme ve sürümleme."),
    };

    // Uzmanlık adı → skill adları. Ortak skill'ler tek kayıt olarak paylaşılır.
    public static readonly IReadOnlyDictionary<string, string[]> SpecializationSkills =
        new Dictionary<string, string[]>
        {
            ["Frontend"] = new[]
            {
                "HTML ve CSS", "JavaScript", "TypeScript", "React",
                "REST API", "Git ve Versiyon Kontrolü",
            },
            ["Backend"] = new[]
            {
                "C#", "ASP.NET Core", "REST API", "SQL",
                "Entity Framework Core", "Web Uygulama Güvenliği", "Git ve Versiyon Kontrolü",
            },
            ["Full Stack"] = new[]
            {
                "JavaScript", "TypeScript", "React", "C#",
                "ASP.NET Core", "REST API", "SQL", "Git ve Versiyon Kontrolü",
            },
            ["Mobile"] = new[]
            {
                "Dart", "Flutter", "Mobil Arayüz Tasarımı", "REST API", "Git ve Versiyon Kontrolü",
            },
            ["SOC"] = new[]
            {
                "Ağ Temelleri", "Linux", "SIEM ve Log Analizi", "Olay Müdahalesi", "Tehdit Tespiti",
            },
            ["Penetration Testing"] = new[]
            {
                "Ağ Temelleri", "Linux", "Python", "Web Uygulama Güvenliği",
                "Zafiyet Analizi", "Sızma Testi Metodolojisi",
            },
            ["Network Security"] = new[]
            {
                "Ağ Temelleri", "Linux", "Güvenlik Duvarı ve IDS/IPS",
                "SIEM ve Log Analizi", "Kriptografi Temelleri", "Tehdit Tespiti",
            },
            ["Data Analyst"] = new[]
            {
                "SQL", "Python", "İstatistik", "Veri Görselleştirme",
                "Veri Temizleme ve Hazırlama", "Excel ve Tablolama",
            },
            ["Data Science"] = new[]
            {
                "Python", "SQL", "İstatistik", "Veri Temizleme ve Hazırlama",
                "Veri Görselleştirme", "Makine Öğrenmesi",
            },
            ["AI / Machine Learning"] = new[]
            {
                "Python", "İstatistik", "Doğrusal Cebir", "Makine Öğrenmesi",
                "Derin Öğrenme", "MLOps ve Model Dağıtımı",
            },
        };

    // İçerik başlığı → skill adı. Yalnızca başlık/açıklamada açıkça geçen,
    // doğrulanmış eşleştirmeler eklenir.
    public static readonly IReadOnlyList<(string ContentTitle, string SkillName)> ContentSkillMappings =
        new[]
        {
            ("ASP.NET Core Web API Development", "ASP.NET Core"),
        };

    // Quiz başlığı → skill adı (Quiz.SkillId).
    public static readonly IReadOnlyList<(string QuizTitle, string SkillName)> QuizSkillMappings =
        new[]
        {
            ("ASP.NET Core Temelleri", "ASP.NET Core"),
        };

    /// <returns>
    /// Uygulanamayan eşleştirmeler için uyarılar (kayıt yok, birden fazla
    /// eşleşme vb.). Bu durumlarda tahminle eşleştirme yapılmaz.
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

        foreach (var definition in Skills)
        {
            if (skillsByName.ContainsKey(definition.Name))
            {
                continue;
            }

            var skill = new Skill
            {
                Id = Guid.NewGuid(),
                Name = definition.Name,
                Description = definition.Description,
                Category = definition.Category,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
            };

            db.Skills.Add(skill);
            skillsByName[skill.Name] = skill;
        }

        var specializationNames = SpecializationSkills.Keys.ToList();

        var specializations = await db.Specializations
            .Where(s => specializationNames.Contains(s.Name))
            .ToListAsync();

        var existingLinks = (await db.SpecializationSkills
                .Select(ss => new { ss.SpecializationId, ss.SkillId })
                .ToListAsync())
            .Select(l => (l.SpecializationId, l.SkillId))
            .ToHashSet();

        foreach (var specialization in specializations)
        {
            // Bulunamayan (ör. yeniden adlandırılmış) uzmanlık atlanır.
            if (!SpecializationSkills.TryGetValue(specialization.Name, out var skillNames))
            {
                continue;
            }

            foreach (var skillName in skillNames)
            {
                var skillId = skillsByName[skillName].Id;

                if (!existingLinks.Add((specialization.Id, skillId)))
                {
                    continue;
                }

                db.SpecializationSkills.Add(new SpecializationSkill
                {
                    Id = Guid.NewGuid(),
                    SpecializationId = specialization.Id,
                    SkillId = skillId,
                });
            }
        }

        await SeedContentSkillsAsync(db, skillsByName, warnings);
        await SeedQuizSkillsAsync(db, skillsByName, warnings);

        await db.SaveChangesAsync();

        foreach (var warning in warnings)
        {
            logger?.LogWarning("Skill seed: {Warning}", warning);
        }

        return warnings;
    }

    private static async Task SeedContentSkillsAsync(
        MenzilimDbContext db,
        IReadOnlyDictionary<string, Skill> skillsByName,
        List<string> warnings)
    {
        foreach (var (contentTitle, skillName) in ContentSkillMappings)
        {
            var skill = RequireSkill(skillsByName, skillName);

            var contents = await db.Contents
                .Where(c => c.Title == contentTitle)
                .ToListAsync();

            if (contents.Count != 1)
            {
                warnings.Add(contents.Count == 0
                    ? $"'{contentTitle}' başlıklı içerik bulunamadı; '{skillName}' eşleştirmesi atlandı."
                    : $"'{contentTitle}' başlıklı {contents.Count} içerik var; '{skillName}' eşleştirmesi belirsiz olduğu için atlandı.");
                continue;
            }

            var contentId = contents[0].Id;

            var exists = await db.ContentSkills
                .AnyAsync(cs => cs.ContentId == contentId && cs.SkillId == skill.Id);

            if (exists)
            {
                continue;
            }

            db.ContentSkills.Add(new ContentSkill
            {
                Id = Guid.NewGuid(),
                ContentId = contentId,
                SkillId = skill.Id,
            });
        }
    }

    private static async Task SeedQuizSkillsAsync(
        MenzilimDbContext db,
        IReadOnlyDictionary<string, Skill> skillsByName,
        List<string> warnings)
    {
        foreach (var (quizTitle, skillName) in QuizSkillMappings)
        {
            var skill = RequireSkill(skillsByName, skillName);

            var quizzes = await db.Quizzes
                .Where(q => q.Title == quizTitle)
                .ToListAsync();

            if (quizzes.Count != 1)
            {
                warnings.Add(quizzes.Count == 0
                    ? $"'{quizTitle}' başlıklı quiz bulunamadı; '{skillName}' eşleştirmesi atlandı."
                    : $"'{quizTitle}' başlıklı {quizzes.Count} quiz var; '{skillName}' eşleştirmesi belirsiz olduğu için atlandı.");
                continue;
            }

            var quiz = quizzes[0];

            if (quiz.SkillId is null)
            {
                quiz.SkillId = skill.Id;
            }
            else if (quiz.SkillId != skill.Id)
            {
                // Elle atanmış farklı bir skill ezilmez.
                warnings.Add(
                    $"'{quizTitle}' quiz'i zaten başka bir skill'e bağlı; mevcut değer korundu.");
            }
        }
    }

    private static Skill RequireSkill(
        IReadOnlyDictionary<string, Skill> skillsByName,
        string skillName)
    {
        // Eşleştirme tabloları katalogla aynı dosyada; bulunamaması kod hatasıdır.
        return skillsByName.TryGetValue(skillName, out var skill)
            ? skill
            : throw new InvalidOperationException(
                $"Skill kataloğunda '{skillName}' tanımlı değil.");
    }
}
