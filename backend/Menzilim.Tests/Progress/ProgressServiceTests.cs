using Menzilim.Application.DTOs.Progress;
using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Interfaces.Skills;
using Menzilim.Application.Services.Progress;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.Progress;

public class ProgressServiceTests
{
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly Guid SpecializationId = Guid.NewGuid();
    private static readonly Guid ProfessionId = Guid.NewGuid();

    private static readonly Guid Skill1Id = Guid.NewGuid();
    private static readonly Guid Skill2Id = Guid.NewGuid();
    private static readonly Guid Skill3Id = Guid.NewGuid();

    private static readonly Guid Content1Id = Guid.NewGuid();
    private static readonly Guid Content2Id = Guid.NewGuid();
    private static readonly Guid Content3Id = Guid.NewGuid();

    private static readonly Guid Quiz1Id = Guid.NewGuid();
    private static readonly Guid Quiz2Id = Guid.NewGuid();

    private static readonly Guid Plan1Id = Guid.NewGuid();
    private static readonly Guid Plan2Id = Guid.NewGuid();
    private static readonly Guid Task1Id = Guid.NewGuid();
    private static readonly Guid Task2Id = Guid.NewGuid();
    private static readonly Guid Task3Id = Guid.NewGuid();

    private static readonly DateTime Today = DateTime.UtcNow.Date;
    private static readonly DateTime Yesterday = Today.AddDays(-1);

    private static readonly MockUserRepository UserRepository = new();
    private static readonly MockContentProgressRepository ContentProgressRepository = new();
    private static readonly MockSkillRepository SkillRepository = new();
    private static readonly MockQuizRepository QuizRepository = new();
    private static readonly MockDailyPlanRepository DailyPlanRepository = new();

    private static readonly ProgressService Service;

    static ProgressServiceTests()
    {
        Service = new ProgressService(
            UserRepository,
            ContentProgressRepository,
            SkillRepository,
            QuizRepository,
            DailyPlanRepository);
    }

    private static UserProfile MakeProfile(
        Guid? specializationId = null,
        Guid? professionId = null,
        string experienceLevel = "Beginner",
        string careerGoal = "Test goal",
        int dailyLearningMinutes = 60)
    {
        return new UserProfile
        {
            Id = Guid.NewGuid(),
            UserId = UserId,
            ProfessionId = professionId ?? ProfessionId,
            SpecializationId = specializationId ?? SpecializationId,
            ExperienceLevel = experienceLevel,
            CareerGoal = careerGoal,
            DailyLearningMinutes = dailyLearningMinutes
        };
    }

    private static User MakeUser(UserProfile? profile = null)
    {
        return new User
        {
            Id = UserId,
            Email = "test@test.com",
            FirstName = "Test",
            LastName = "User",
            Profile = profile ?? MakeProfile()
        };
    }

    private static Skill MakeSkill(string name, Guid? skillId = null, string category = "Test")
    {
        return new Skill
        {
            Id = skillId ?? Guid.NewGuid(),
            Name = name,
            Category = category,
            IsActive = true,
            CreatedAt = Today
        };
    }

    private static ContentSkill MakeContentSkill(Guid contentId, Guid skillId)
    {
        return new ContentSkill
        {
            Id = Guid.NewGuid(),
            ContentId = contentId,
            SkillId = skillId
        };
    }

    private static Domain.Quiz MakeQuiz(Guid? skillId = null, Guid? quizId = null)
    {
        return new Domain.Quiz
        {
            Id = quizId ?? Guid.NewGuid(),
            Title = "Test Quiz",
            SkillId = skillId,
            IsActive = true,
            CreatedAt = Today
        };
    }

    private static QuizAttempt MakeQuizAttempt(
        Guid quizId,
        int score,
        DateTime? completedAt = null)
    {
        return new QuizAttempt
        {
            Id = Guid.NewGuid(),
            QuizId = quizId,
            UserId = UserId,
            Score = score,
            CorrectAnswers = score,
            TotalQuestions = 100,
            CompletedAt = completedAt ?? Today
        };
    }

    private static UserContentProgress MakeContentProgress(
        Guid contentId,
        bool isCompleted = false,
        DateTime? completedAt = null)
    {
        return new UserContentProgress
        {
            Id = Guid.NewGuid(),
            UserId = UserId,
            ContentId = contentId,
            StartedAt = Today.AddDays(-1),
            IsCompleted = isCompleted,
            CompletedAt = completedAt
        };
    }

    private static Domain.DailyPlan MakePlan(
        DateTime date,
        Guid? planId = null,
        bool isCompleted = false,
        params (Guid TaskId, string TaskType, int Minutes, bool IsCompleted, Guid? ContentId)[] tasks)
    {
        var plan = new Domain.DailyPlan
        {
            Id = planId ?? Guid.NewGuid(),
            UserId = UserId,
            Date = date,
            Title = "Test Plan",
            IsCompleted = isCompleted,
            CreatedAt = date,
            Tasks = new List<DailyTask>()
        };

        foreach (var (taskId, taskType, minutes, taskIsCompleted, contentId) in tasks)
        {
            plan.Tasks.Add(new DailyTask
            {
                Id = taskId,
                DailyPlanId = plan.Id,
                Title = $"Task {taskId}",
                TaskType = taskType,
                EstimatedMinutes = minutes,
                IsCompleted = taskIsCompleted,
                CompletedAt = taskIsCompleted ? date : null,
                ContentId = contentId
            });
        }

        return plan;
    }

    private static SkillProgressResponse MakeSkillProgress(
        string skillName,
        Guid skillId,
        int progressPercent,
        int totalContentCount = 0,
        int completedContentCount = 0,
        int totalQuizCount = 0,
        int attemptedQuizCount = 0,
        string category = "Test")
    {
        return new SkillProgressResponse
        {
            SkillId = skillId,
            SkillName = skillName,
            Category = category,
            ProgressPercent = progressPercent,
            TotalContentCount = totalContentCount,
            CompletedContentCount = completedContentCount,
            InProgressContentCount = totalContentCount - completedContentCount,
            TotalQuizCount = totalQuizCount,
            AttemptedQuizCount = attemptedQuizCount,
            QuizAttemptCount = attemptedQuizCount,
            BestQuizScore = progressPercent > 0 ? progressPercent : null,
            LatestQuizScore = progressPercent > 0 ? progressPercent : null
        };
    }

    #region Mock Implementations

    private class MockUserRepository : IUserRepository
    {
        private User? _user;

        public void SetupUser(User? user) => _user = user;

        public Task<User?> GetByEmailAsync(string email) => Task.FromResult<User?>(null);

        public Task<User?> GetByIdAsync(Guid id) => Task.FromResult(_user);

        public Task<User?> GetByIdWithProfileDetailsAsync(Guid userId) => Task.FromResult(_user);

        public Task AddAsync(User user) => Task.CompletedTask;

        public Task AddProfileAsync(UserProfile profile) => Task.CompletedTask;

        public Task SaveChangesAsync() => Task.CompletedTask;
    }

    private class MockContentProgressRepository : IUserContentProgressRepository
    {
        private List<UserContentProgress> _progress = new();

        public void SetupProgress(List<UserContentProgress> progress) => _progress = progress;

        public Task<UserContentProgress?> GetAsync(Guid userId, Guid contentId)
            => Task.FromResult(_progress.FirstOrDefault(p => p.UserId == userId && p.ContentId == contentId));

        public Task<List<UserContentProgress>> GetByUserAsync(Guid userId)
            => Task.FromResult(_progress.Where(p => p.UserId == userId).ToList());

        public Task AddAsync(UserContentProgress progress)
        {
            _progress.Add(progress);
            return Task.CompletedTask;
        }

        public Task SaveChangesAsync() => Task.CompletedTask;
    }

    private class MockSkillRepository : ISkillRepository
    {
    public Task<List<SpecializationSkill>> GetSpecializationSkillsAsync(Guid specializationId) =>
        Task.FromResult(new List<SpecializationSkill>());

        private List<Skill> _skills = new();
        private List<ContentSkill> _contentLinks = new();
        private List<Domain.Quiz> _quizzes = new();
        private List<QuizAttempt> _quizAttempts = new();

        public void SetupSkills(List<Skill> skills) => _skills = skills;
        public void SetupContentLinks(List<ContentSkill> links) => _contentLinks = links;
        public void SetupQuizzes(List<Domain.Quiz> quizzes) => _quizzes = quizzes;
        public void SetupQuizAttempts(List<QuizAttempt> attempts) => _quizAttempts = attempts;

        public Task<bool> SpecializationExistsAsync(Guid specializationId) => Task.FromResult(true);

        public Task<List<Skill>> GetActiveBySpecializationAsync(Guid specializationId)
            => Task.FromResult(_skills);

        public Task<List<ContentSkill>> GetActiveContentLinksAsync(IReadOnlyCollection<Guid> skillIds)
            => Task.FromResult(_contentLinks);

        public Task<List<Domain.Quiz>> GetActiveQuizzesAsync(IReadOnlyCollection<Guid> skillIds)
            => Task.FromResult(_quizzes);

        public Task<List<QuizAttempt>> GetUserQuizAttemptsAsync(Guid userId, IReadOnlyCollection<Guid> quizIds)
            => Task.FromResult(_quizAttempts.Where(a => quizIds.Contains(a.QuizId)).ToList());
    }

    private class MockQuizRepository : IQuizRepository
    {
        private List<Domain.Quiz> _quizzes = new();
        private List<QuizAttempt> _attempts = new();

        public void SetupQuizzes(List<Domain.Quiz> quizzes) => _quizzes = quizzes;
        public void SetupAttempts(List<QuizAttempt> attempts) => _attempts = attempts;

        public Task<List<Domain.Quiz>> GetAllActiveAsync() => Task.FromResult(_quizzes);

        public Task<Domain.Quiz?> GetByIdWithQuestionsAsync(Guid id)
            => Task.FromResult(_quizzes.FirstOrDefault(q => q.Id == id));

        public Task<Domain.Quiz?> GetFirstActiveWithQuestionsAsync()
            => Task.FromResult(_quizzes.FirstOrDefault(q => q.IsActive));

        public Task AddAttemptAsync(QuizAttempt attempt)
        {
            _attempts.Add(attempt);
            return Task.CompletedTask;
        }

        public Task<int> GetAttemptCountByUserAsync(Guid userId)
            => Task.FromResult(_attempts.Count(a => a.UserId == userId));

        public Task<List<QuizAttempt>> GetByUserAsync(Guid userId)
            => Task.FromResult(_attempts.Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CompletedAt)
                .ThenByDescending(a => a.Id)
                .ToList());

        public Task SaveChangesAsync() => Task.CompletedTask;
    }

    private class MockDailyPlanRepository : IDailyPlanRepository
    {
    public Task<List<DailyTask>> GetTasksByProjectStepAsync(Guid userProjectStepId) =>
        Task.FromResult(new List<DailyTask>());

        private Domain.DailyPlan? _todayPlan;
        private List<Domain.DailyPlan> _allPlans = new();

        public void SetupTodayPlan(Domain.DailyPlan? plan) => _todayPlan = plan;
        public void SetupAllPlans(List<Domain.DailyPlan> plans) => _allPlans = plans;

        public Task<Domain.DailyPlan?> GetByUserAndDateAsync(Guid userId, DateTime date)
            => Task.FromResult(_todayPlan);

        public Task<DailyTask?> GetTaskByIdAsync(Guid taskId) => Task.FromResult<DailyTask?>(null);

        public Task AddAsync(Domain.DailyPlan dailyPlan)
        {
            _allPlans.Add(dailyPlan);
            return Task.CompletedTask;
        }

        public Task<List<Domain.DailyPlan>> GetAllByUserAsync(Guid userId)
            => Task.FromResult(_allPlans);

        public Task SaveChangesAsync() => Task.CompletedTask;
    }

    #endregion

    [Fact]
    public async Task GetMyProgressAsync_WithoutProfile_ReturnsEmptyResponse()
    {
        // Arrange
        UserRepository.SetupUser(null);

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.NotNull(result);
        Assert.Equal(0, result.Overview.CompletedTaskCount);
        Assert.Equal(0, result.Overview.EstimatedLearningMinutes);
        Assert.Equal(0, result.Overview.CompletedPlanCount);
        Assert.Equal(0, result.Overview.ActiveDayCount);
        Assert.False(result.Today.HasPlan);
        Assert.Equal(0, result.Today.TotalTasks);
        Assert.Equal(0, result.Today.CompletedTasks);
        Assert.Equal(0, result.Today.TotalMinutes);
        Assert.Equal(0, result.Today.CompletedMinutes);
        Assert.Equal(0, result.Today.ProgressPercent);
        Assert.Equal(0, result.Content.CompletedCount);
        Assert.Equal(0, result.Content.InProgressCount);
        Assert.Equal(0, result.Quiz.AttemptCount);
        Assert.Equal(0, result.Quiz.DistinctQuizCount);
        Assert.Null(result.Quiz.BestScore);
        Assert.Null(result.Quiz.AverageScore);
        Assert.Null(result.Quiz.LatestScore);
        Assert.Null(result.Quiz.LatestAttemptAt);
        Assert.Equal(0, result.Skills.TotalCount);
        Assert.Equal(0, result.Skills.StartedCount);
        Assert.Empty(result.Skills.Strongest);
        Assert.Empty(result.Skills.Focus);
    }

    [Fact]
    public async Task GetMyProgressAsync_WithProfile_ButNoActivity_ReturnsZeroProgress()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());
        DailyPlanRepository.SetupTodayPlan(null);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan>());

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(0, result.Overview.CompletedTaskCount);
        Assert.Equal(0, result.Overview.EstimatedLearningMinutes);
        Assert.Equal(0, result.Overview.CompletedPlanCount);
        Assert.Equal(0, result.Overview.ActiveDayCount);
        Assert.False(result.Today.HasPlan);
        Assert.Equal(0, result.Content.CompletedCount);
        Assert.Equal(0, result.Content.InProgressCount);
        Assert.Equal(0, result.Quiz.AttemptCount);
        Assert.Equal(0, result.Skills.TotalCount);
        Assert.Equal(0, result.Skills.StartedCount);
    }

    [Fact]
    public async Task GetMyProgressAsync_Overview_CalculatesCorrectly()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());

        var plans = new List<Domain.DailyPlan>
        {
            MakePlan(Today, planId: Plan1Id, isCompleted: true,
                (Task1Id, "Learn", 30, true, null),
                (Task2Id, "Quiz", 15, true, null)),
            MakePlan(Yesterday, planId: Plan2Id, isCompleted: false,
                (Task3Id, "Learn", 20, false, null))
        };

        DailyPlanRepository.SetupTodayPlan(plans[0]);
        DailyPlanRepository.SetupAllPlans(plans);

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(2, result.Overview.CompletedTaskCount);
        Assert.Equal(45, result.Overview.EstimatedLearningMinutes);
        Assert.Equal(1, result.Overview.CompletedPlanCount);
        Assert.Equal(2, result.Overview.ActiveDayCount);
    }

    [Fact]
    public async Task GetMyProgressAsync_Today_NoPlan_ReturnsZero()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());
        DailyPlanRepository.SetupTodayPlan(null);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan>());

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.False(result.Today.HasPlan);
        Assert.Equal(0, result.Today.TotalTasks);
        Assert.Equal(0, result.Today.CompletedTasks);
        Assert.Equal(0, result.Today.TotalMinutes);
        Assert.Equal(0, result.Today.CompletedMinutes);
        Assert.Equal(0, result.Today.ProgressPercent);
    }

    [Fact]
    public async Task GetMyProgressAsync_Today_WithPlan_CalculatesCorrectly()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());

        var plan = MakePlan(Today, planId: Plan1Id, isCompleted: false,
            (Task1Id, "Learn", 30, true, null),
            (Task2Id, "Practice", 20, false, null),
            (Task3Id, "Quiz", 10, true, null));

        DailyPlanRepository.SetupTodayPlan(plan);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan> { plan });

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.True(result.Today.HasPlan);
        Assert.Equal(3, result.Today.TotalTasks);
        Assert.Equal(2, result.Today.CompletedTasks);
        Assert.Equal(60, result.Today.TotalMinutes);
        Assert.Equal(40, result.Today.CompletedMinutes);
        Assert.Equal(67, result.Today.ProgressPercent);
    }

    [Fact]
    public async Task GetMyProgressAsync_Today_ProgressPercent_ClampsToHundred()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());

        var plan = MakePlan(Today, planId: Plan1Id, isCompleted: false,
            (Task1Id, "Learn", 10, true, null));

        DailyPlanRepository.SetupTodayPlan(plan);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan> { plan });

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(100, result.Today.ProgressPercent);
    }

    [Fact]
    public async Task GetMyProgressAsync_Today_ProgressPercent_ZeroWhenNoMinutes()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());

        var plan = MakePlan(Today, planId: Plan1Id, isCompleted: false);

        DailyPlanRepository.SetupTodayPlan(plan);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan> { plan });

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(0, result.Today.ProgressPercent);
    }

    [Fact]
    public async Task GetMyProgressAsync_Content_DuplicateSafe_CalculatesCorrectly()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());

        var contentProgress = new List<UserContentProgress>
        {
            MakeContentProgress(Content1Id, isCompleted: true, completedAt: Today),
            MakeContentProgress(Content1Id, isCompleted: false),
            MakeContentProgress(Content2Id, isCompleted: false),
            MakeContentProgress(Content3Id, isCompleted: true, completedAt: Today.AddDays(-1))
        };

        ContentProgressRepository.SetupProgress(contentProgress);
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());
        DailyPlanRepository.SetupTodayPlan(null);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan>());

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(2, result.Content.CompletedCount);
        Assert.Equal(1, result.Content.InProgressCount);
    }

    [Fact]
    public async Task GetMyProgressAsync_Content_CompletedAtWithoutIsCompletedFlag_IsTreatedAsCompleted()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());

        var contentProgress = new List<UserContentProgress>
        {
            MakeContentProgress(Content1Id, isCompleted: false, completedAt: Today)
        };

        ContentProgressRepository.SetupProgress(contentProgress);
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());
        DailyPlanRepository.SetupTodayPlan(null);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan>());

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(1, result.Content.CompletedCount);
        Assert.Equal(0, result.Content.InProgressCount);
    }

    [Fact]
    public async Task GetMyProgressAsync_Quiz_CalculatesCorrectly()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());

        var quizAttempts = new List<QuizAttempt>
        {
            MakeQuizAttempt(Quiz1Id, 80, Today.AddDays(-2)),
            MakeQuizAttempt(Quiz1Id, 90, Today.AddDays(-1)),
            MakeQuizAttempt(Quiz2Id, 70, Today)
        };

        QuizRepository.SetupAttempts(quizAttempts);
        DailyPlanRepository.SetupTodayPlan(null);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan>());

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(3, result.Quiz.AttemptCount);
        Assert.Equal(2, result.Quiz.DistinctQuizCount);
        Assert.Equal(90, result.Quiz.BestScore);
        Assert.Equal(80, result.Quiz.AverageScore);
        Assert.Equal(70, result.Quiz.LatestScore);
        Assert.Equal(Today, result.Quiz.LatestAttemptAt);
    }

    [Fact]
    public async Task GetMyProgressAsync_Quiz_Empty_ReturnsNullScores()
    {
        // Arrange
        UserRepository.SetupUser(MakeUser());
        ContentProgressRepository.SetupProgress(new List<UserContentProgress>());
        SkillRepository.SetupSkills(new List<Skill>());
        QuizRepository.SetupAttempts(new List<QuizAttempt>());
        DailyPlanRepository.SetupTodayPlan(null);
        DailyPlanRepository.SetupAllPlans(new List<Domain.DailyPlan>());

        // Act
        var result = await Service.GetMyProgressAsync(UserId);

        // Assert
        Assert.Equal(0, result.Quiz.AttemptCount);
        Assert.Equal(0, result.Quiz.DistinctQuizCount);
        Assert.Null(result.Quiz.BestScore);
        Assert.Null(result.Quiz.AverageScore);
        Assert.Null(result.Quiz.LatestScore);
        Assert.Null(result.Quiz.LatestAttemptAt);
    }
}