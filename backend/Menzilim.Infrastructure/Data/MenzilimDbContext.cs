using Microsoft.EntityFrameworkCore;
using Menzilim.Domain;

namespace Menzilim.Infrastructure.Data;

public class MenzilimDbContext : DbContext
{
    public MenzilimDbContext(DbContextOptions<MenzilimDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<Profession> Professions => Set<Profession>();
    public DbSet<Specialization> Specializations => Set<Specialization>();
    public DbSet<Skill> Skills => Set<Skill>();
    public DbSet<UserSkill> UserSkills => Set<UserSkill>();
    public DbSet<SpecializationSkill> SpecializationSkills => Set<SpecializationSkill>();
    public DbSet<ContentSkill> ContentSkills => Set<ContentSkill>();
    public DbSet<Content> Contents => Set<Content>();
    public DbSet<ContentTag> ContentTags => Set<ContentTag>();
    public DbSet<ContentProfession> ContentProfessions => Set<ContentProfession>();
    public DbSet<LearningPath> LearningPaths => Set<LearningPath>();
    public DbSet<LearningItem> LearningItems => Set<LearningItem>();
    public DbSet<Quiz> Quizzes => Set<Quiz>();
    public DbSet<Question> Questions => Set<Question>();
    public DbSet<QuizAttempt> QuizAttempts => Set<QuizAttempt>();
    public DbSet<DailyPlan> DailyPlans => Set<DailyPlan>();
    public DbSet<DailyTask> DailyTasks => Set<DailyTask>();
    public DbSet<UserProgress> UserProgresses => Set<UserProgress>();
    public DbSet<UserActivity> UserActivities => Set<UserActivity>();
    public DbSet<UserContentProgress> UserContentProgresses => Set<UserContentProgress>();
    public DbSet<NewsItem> NewsItems => Set<NewsItem>();
    public DbSet<NewsItemSkill> NewsItemSkills => Set<NewsItemSkill>();
    public DbSet<UserProject> UserProjects => Set<UserProject>();
    public DbSet<UserProjectStep> UserProjectSteps => Set<UserProjectStep>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>()
            .HasOne(u => u.Profile)
            .WithOne(p => p.User)
            .HasForeignKey<UserProfile>(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserProfile>()
            .HasOne(p => p.Profession)
            .WithMany()
            .HasForeignKey(p => p.ProfessionId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserProfile>()
            .HasOne(p => p.Specialization)
            .WithMany(s => s.UserProfiles)
            .HasForeignKey(p => p.SpecializationId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Specialization>()
            .HasOne(s => s.Profession)
            .WithMany(p => p.Specializations)
            .HasForeignKey(s => s.ProfessionId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserSkill>()
            .HasOne(us => us.User)
            .WithMany()
            .HasForeignKey(us => us.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserSkill>()
            .HasOne(us => us.Skill)
            .WithMany(s => s.UserSkills)
            .HasForeignKey(us => us.SkillId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SpecializationSkill>()
            .HasOne(ss => ss.Specialization)
            .WithMany(s => s.SpecializationSkills)
            .HasForeignKey(ss => ss.SpecializationId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SpecializationSkill>()
            .HasOne(ss => ss.Skill)
            .WithMany(s => s.SpecializationSkills)
            .HasForeignKey(ss => ss.SkillId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ContentSkill>()
            .HasOne(cs => cs.Content)
            .WithMany(c => c.Skills)
            .HasForeignKey(cs => cs.ContentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ContentSkill>()
            .HasOne(cs => cs.Skill)
            .WithMany(s => s.ContentSkills)
            .HasForeignKey(cs => cs.SkillId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Quiz>()
            .HasOne(q => q.Skill)
            .WithMany(s => s.Quizzes)
            .HasForeignKey(q => q.SkillId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<ContentTag>()
            .HasOne(ct => ct.Content)
            .WithMany(c => c.Tags)
            .HasForeignKey(ct => ct.ContentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ContentProfession>()
            .HasOne(cp => cp.Content)
            .WithMany(c => c.Professions)
            .HasForeignKey(cp => cp.ContentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ContentProfession>()
            .HasOne(cp => cp.Profession)
            .WithMany(p => p.ContentProfessions)
            .HasForeignKey(cp => cp.ProfessionId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<LearningItem>()
            .HasOne(li => li.LearningPath)
            .WithMany(lp => lp.Items)
            .HasForeignKey(li => li.LearningPathId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<LearningItem>()
            .HasOne(li => li.Content)
            .WithMany()
            .HasForeignKey(li => li.ContentId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<LearningItem>()
            .HasOne(li => li.Skill)
            .WithMany()
            .HasForeignKey(li => li.SkillId)
            .OnDelete(DeleteBehavior.SetNull);

        // Living Project: şablon (LearningPath) silinirse kullanıcı projesi
        // sahipsiz kalmasın diye Restrict; kullanıcı silinirse Cascade.
        modelBuilder.Entity<UserProject>()
            .HasOne(up => up.User)
            .WithMany()
            .HasForeignKey(up => up.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserProject>()
            .HasOne(up => up.LearningPath)
            .WithMany()
            .HasForeignKey(up => up.LearningPathId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserProjectStep>()
            .HasOne(s => s.UserProject)
            .WithMany(p => p.Steps)
            .HasForeignKey(s => s.UserProjectId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserProjectStep>()
            .HasOne(s => s.LearningItem)
            .WithMany()
            .HasForeignKey(s => s.LearningItemId)
            .OnDelete(DeleteBehavior.Restrict);

        // Bir kullanıcı bir şablondan tek proje yürütür.
        modelBuilder.Entity<UserProject>()
            .HasIndex(up => new { up.UserId, up.LearningPathId })
            .IsUnique();

        // Aynı adım projede iki kez oluşturulmasın.
        modelBuilder.Entity<UserProjectStep>()
            .HasIndex(s => new { s.UserProjectId, s.LearningItemId })
            .IsUnique();

        modelBuilder.Entity<Question>()
            .HasOne(q => q.Quiz)
            .WithMany(qz => qz.Questions)
            .HasForeignKey(q => q.QuizId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<QuizAttempt>()
            .HasOne(qa => qa.Quiz)
            .WithMany(q => q.Attempts)
            .HasForeignKey(qa => qa.QuizId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<QuizAttempt>()
            .HasOne(qa => qa.User)
            .WithMany()
            .HasForeignKey(qa => qa.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<DailyTask>()
            .HasOne(dt => dt.DailyPlan)
            .WithMany(dp => dp.Tasks)
            .HasForeignKey(dt => dt.DailyPlanId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<DailyTask>()
            .HasOne(dt => dt.Content)
            .WithMany()
            .HasForeignKey(dt => dt.ContentId)
            .OnDelete(DeleteBehavior.SetNull);

        // Görev bir proje adımından üretilebilir. Kullanıcı silinince hem
        // görevler hem adımlar zaten cascade ile gider; bu bağda veritabanı
        // eylemi NO ACTION olur (çoklu cascade yolu hatası önlenir), EF
        // bellekteki referansı temizler.
        modelBuilder.Entity<DailyTask>()
            .HasOne(dt => dt.UserProjectStep)
            .WithMany()
            .HasForeignKey(dt => dt.UserProjectStepId)
            .OnDelete(DeleteBehavior.ClientSetNull);

        modelBuilder.Entity<NewsItemSkill>()
            .HasOne(ns => ns.NewsItem)
            .WithMany(n => n.Skills)
            .HasForeignKey(ns => ns.NewsItemId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<NewsItemSkill>()
            .HasOne(ns => ns.Skill)
            .WithMany()
            .HasForeignKey(ns => ns.SkillId)
            .OnDelete(DeleteBehavior.Cascade);

        // DailyPlan.UserId için ilişki tanımlı değildi: kullanıcı silinince
        // planlar ve görevleri sahipsiz kalıyordu.
        modelBuilder.Entity<DailyPlan>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(dp => dp.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserProgress>()
            .HasOne(up => up.User)
            .WithMany()
            .HasForeignKey(up => up.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<UserActivity>()
            .HasOne(ua => ua.User)
            .WithMany()
            .HasForeignKey(ua => ua.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<DailyPlan>()
            .HasIndex(dp => new { dp.UserId, dp.Date })
            .IsUnique();

        modelBuilder.Entity<UserSkill>()
            .HasIndex(us => new { us.UserId, us.SkillId })
            .IsUnique();

        modelBuilder.Entity<SpecializationSkill>()
            .HasIndex(ss => new { ss.SpecializationId, ss.SkillId })
            .IsUnique();

        modelBuilder.Entity<ContentSkill>()
            .HasIndex(cs => new { cs.ContentId, cs.SkillId })
            .IsUnique();

        modelBuilder.Entity<NewsItemSkill>()
            .HasIndex(ns => new { ns.NewsItemId, ns.SkillId })
            .IsUnique();

        // Bir kullanıcının bir içerik için tek ilerleme kaydı olur.
        modelBuilder.Entity<UserContentProgress>()
            .HasIndex(p => new { p.UserId, p.ContentId })
            .IsUnique();

        // Aynı içerik bir mesleğe yalnızca bir kez bağlanır.
        modelBuilder.Entity<ContentProfession>()
            .HasIndex(cp => new { cp.ContentId, cp.ProfessionId })
            .IsUnique();

        // Aynı haber iki kez eklenmesin (seed ve ileride feed alımı).
        // (Email'deki gibi index nedeniyle nvarchar(450) olur.)
        modelBuilder.Entity<NewsItem>()
            .HasIndex(n => n.SourceUrl)
            .IsUnique();

        // Seed, skill'leri isimle bulup tekrar eklemeyi önleyebilsin diye
        // benzersiz. (Email'deki gibi index nedeniyle nvarchar(450) olur.)
        modelBuilder.Entity<Skill>()
            .HasIndex(s => s.Name)
            .IsUnique();
    }
}
