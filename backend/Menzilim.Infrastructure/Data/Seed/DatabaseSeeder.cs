using Microsoft.EntityFrameworkCore;
using Menzilim.Domain;

namespace Menzilim.Infrastructure.Data.Seed;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(MenzilimDbContext db)
    {
        if (!await db.Professions.AnyAsync())
        {
            var software = new Profession
            {
                Id = Guid.NewGuid(),
                Name = "Yazılım Geliştirici",
                Description = "Yazılım uygulamaları ve sistemleri geliştiren profesyonel.",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            var cybersecurity = new Profession
            {
                Id = Guid.NewGuid(),
                Name = "Siber Güvenlik",
                Description = "Bilgi sistemlerini ve ağları güvenlik tehditlerine karşı koruma alanı.",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            var data = new Profession
            {
                Id = Guid.NewGuid(),
                Name = "Veri Uzmanı",
                Description = "Veri analizi, veri bilimi ve yapay zeka alanlarında çalışan profesyonel.",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            db.Professions.AddRange(software, cybersecurity, data);

            await db.SaveChangesAsync();

            var specializations = new[]
            {
                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = software.Id,
                    Name = "Frontend",
                    Description = "Web uygulamalarının kullanıcı arayüzlerini geliştirme.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = software.Id,
                    Name = "Backend",
                    Description = "Sunucu tarafı uygulamalar, API ve veritabanı geliştirme.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = software.Id,
                    Name = "Full Stack",
                    Description = "Frontend ve backend geliştirmeyi birlikte kapsayan alan.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = software.Id,
                    Name = "Mobile",
                    Description = "Mobil uygulama geliştirme.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = cybersecurity.Id,
                    Name = "SOC",
                    Description = "Güvenlik operasyonları ve olay izleme.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = cybersecurity.Id,
                    Name = "Penetration Testing",
                    Description = "Sistem ve uygulamalardaki güvenlik açıklarını test etme.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = cybersecurity.Id,
                    Name = "Network Security",
                    Description = "Ağ altyapılarının güvenliğini sağlama.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = data.Id,
                    Name = "Data Analyst",
                    Description = "Verileri analiz ederek anlamlı içgörüler çıkarma.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = data.Id,
                    Name = "Data Science",
                    Description = "Veri bilimi ve istatistiksel modelleme.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },

                new Specialization
                {
                    Id = Guid.NewGuid(),
                    ProfessionId = data.Id,
                    Name = "AI / Machine Learning",
                    Description = "Yapay zeka ve makine öğrenmesi uygulamaları.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            db.Specializations.AddRange(specializations);

            await db.SaveChangesAsync();
        }

        if (!await db.Quizzes.AnyAsync())
        {
            var quiz = new Quiz
            {
                Id = Guid.NewGuid(),
                Title = "ASP.NET Core Temelleri",
                Description = "ASP.NET Core mimarisi, Web API ve Dependency Injection temelleri.",
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                Questions = new List<Question>
                {
                    new Question
                    {
                        Id = Guid.NewGuid(),
                        Text = "ASP.NET Core nedir?",
                        OptionA = "Açık kaynaklı, platformlar arası modern bir web geliştirme çatısıdır.",
                        OptionB = "Yalnızca Windows işletim sisteminde çalışan bir masaüstü kütüphanesidir.",
                        OptionC = "Bir ilişkisel veritabanı yönetim sistemidir.",
                        OptionD = "Bir CSS ve tasarım kütüphanesidir.",
                        CorrectOption = "A"
                    },
                    new Question
                    {
                        Id = Guid.NewGuid(),
                        Text = "Web API endpoint'i nedir?",
                        OptionA = "İstemcilerin HTTP protokolü üzerinden veri alıp göndermesini sağlayan erişim noktasıdır.",
                        OptionB = "Yalnızca statik HTML sayfaları derlemek için kullanılan şablon motorudur.",
                        OptionC = "Bilgisayarın donanım sürücülerini denetleyen arabirimdir.",
                        OptionD = "Veritabanında yeni bir tablo sütunu açan komuttur.",
                        CorrectOption = "A"
                    },
                    new Question
                    {
                        Id = Guid.NewGuid(),
                        Text = "Dependency Injection ne işe yarar?",
                        OptionA = "Sınıflar arasındaki bağımlılıkları gevşeterek yönetimi ve test edilebilirliği kolaylaştırır.",
                        OptionB = "Veritabanındaki SQL sorgularını otomatik olarak şifreler.",
                        OptionC = "Kullanıcı oturum şifrelerini doğrular.",
                        OptionD = "Ağ paketlerini sıkıştırarak internet hızını artırır.",
                        CorrectOption = "A"
                    }
                }
            };

            db.Quizzes.Add(quiz);
            await db.SaveChangesAsync();
        }
    }
}