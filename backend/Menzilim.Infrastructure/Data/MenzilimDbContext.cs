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
    }
}