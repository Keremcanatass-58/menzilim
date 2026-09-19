using Menzilim.Application.DTOs.Progress;
using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Interfaces.Progress;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Interfaces.Skills;
using Menzilim.Application.Services.Skills;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Progress;

public class ProgressService : IProgressService
{
    private readonly IUserRepository _userRepository;
    private readonly IUserContentProgressRepository _contentProgressRepository;
    private readonly ISkillRepository _skillRepository;
    private readonly IQuizRepository _quizRepository;
    private readonly IDailyPlanRepository _dailyPlanRepository;

    public ProgressService(
        IUserRepository userRepository,
        IUserContentProgressRepository contentProgressRepository,
        ISkillRepository skillRepository,
        IQuizRepository quizRepository,
        IDailyPlanRepository dailyPlanRepository)
    {
        _userRepository = userRepository;
        _contentProgressRepository = contentProgressRepository;
        _skillRepository = skillRepository;
        _quizRepository = quizRepository;
        _dailyPlanRepository = dailyPlanRepository;
    }

    public async Task<ProgressResponse> GetMyProgressAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user?.Profile is null)
        {
            return new ProgressResponse();
        }

        var specializationId = user.Profile.SpecializationId;

        // İçerik progress'ini getir (duplicate-safe hesaplama için)
        var contentProgress = await _contentProgressRepository.GetByUserAsync(userId);

        // Quiz denemelerini getir
        var quizAttempts = await _quizRepository.GetByUserAsync(userId);

        // Skill progress'ini hesapla (mevcut SkillProgressEngine kullanımı)
        var (skillProgress, _) = await LoadSkillProgressAsync(userId, specializationId, contentProgress);

        // Günlük planı getir (bugün)
        var today = DateTime.UtcNow.Date;
        var todayPlan = await _dailyPlanRepository.GetByUserAndDateAsync(userId, today);

        // Tüm planları getir (overview istatistikleri için)
        var allPlans = await _dailyPlanRepository.GetAllByUserAsync(userId);

        return new ProgressResponse
        {
            Overview = CalculateOverview(allPlans),
            Today = CalculateToday(todayPlan),
            Content = CalculateContent(contentProgress),
            Quiz = CalculateQuiz(quizAttempts),
            Skills = CalculateSkills(skillProgress)
        };
    }

    private static ProgressOverview CalculateOverview(List<Domain.DailyPlan> allPlans)
    {
        var completedTaskCount = 0;
        var estimatedLearningMinutes = 0;
        var completedPlanCount = 0;
        var activeDays = new HashSet<DateTime>();

        foreach (var plan in allPlans)
        {
            activeDays.Add(plan.Date.Date);

            foreach (var task in plan.Tasks)
            {
                if (task.IsCompleted)
                {
                    completedTaskCount++;
                    estimatedLearningMinutes += task.EstimatedMinutes;
                }
            }

            if (plan.IsCompleted)
            {
                completedPlanCount++;
            }
        }

        return new ProgressOverview
        {
            CompletedTaskCount = completedTaskCount,
            EstimatedLearningMinutes = estimatedLearningMinutes,
            CompletedPlanCount = completedPlanCount,
            ActiveDayCount = activeDays.Count
        };
    }

    private static ProgressToday CalculateToday(Domain.DailyPlan? todayPlan)
    {
        if (todayPlan is null)
        {
            return new ProgressToday
            {
                HasPlan = false,
                TotalTasks = 0,
                CompletedTasks = 0,
                TotalMinutes = 0,
                CompletedMinutes = 0,
                ProgressPercent = 0
            };
        }

        var totalTasks = todayPlan.Tasks.Count;
        var completedTasks = todayPlan.Tasks.Count(t => t.IsCompleted);
        var totalMinutes = todayPlan.Tasks.Sum(t => t.EstimatedMinutes);
        var completedMinutes = todayPlan.Tasks
            .Where(t => t.IsCompleted)
            .Sum(t => t.EstimatedMinutes);

        var progressPercent = totalMinutes > 0
            ? (int)Math.Round((double)completedMinutes / totalMinutes * 100, MidpointRounding.AwayFromZero)
            : 0;

        progressPercent = Math.Clamp(progressPercent, 0, 100);

        return new ProgressToday
        {
            HasPlan = true,
            TotalTasks = totalTasks,
            CompletedTasks = completedTasks,
            TotalMinutes = totalMinutes,
            CompletedMinutes = completedMinutes,
            ProgressPercent = progressPercent
        };
    }

    private static ProgressContent CalculateContent(IReadOnlyList<UserContentProgress> contentProgress)
    {
        // Duplicate-safe: aynı ContentId için birden fazla kayıt olsa bile
        // tek içerik sayılır. Herhangi bir kayıt tamamlanmışsa içerik tamamlanmıştır.
        var progressByContent = contentProgress
            .GroupBy(p => p.ContentId)
            .ToDictionary(
                g => g.Key,
                g => g.Any(p => p.IsCompleted || p.CompletedAt is not null));

        var completedCount = progressByContent.Count(kv => kv.Value);
        var inProgressCount = progressByContent.Count(kv => !kv.Value);

        return new ProgressContent
        {
            CompletedCount = completedCount,
            InProgressCount = inProgressCount
        };
    }

    private static ProgressQuiz CalculateQuiz(IReadOnlyList<QuizAttempt> quizAttempts)
    {
        if (quizAttempts.Count == 0)
        {
            return new ProgressQuiz();
        }

        var distinctQuizCount = quizAttempts.Select(a => a.QuizId).Distinct().Count();
        var bestScore = quizAttempts.Max(a => a.Score);
        var averageScore = (int)Math.Round(
            quizAttempts.Average(a => a.Score),
            MidpointRounding.AwayFromZero);
        var latestAttempt = quizAttempts.First();
        var latestScore = latestAttempt.Score;
        var latestAttemptAt = latestAttempt.CompletedAt;

        return new ProgressQuiz
        {
            AttemptCount = quizAttempts.Count,
            DistinctQuizCount = distinctQuizCount,
            BestScore = bestScore,
            AverageScore = averageScore,
            LatestScore = latestScore,
            LatestAttemptAt = latestAttemptAt
        };
    }

    private static ProgressSkills CalculateSkills(IReadOnlyList<SkillProgressResponse> skillProgress)
    {
        var totalCount = skillProgress.Count;
        var startedCount = skillProgress.Count(s => s.ProgressPercent > 0);

        var strongest = skillProgress
            .Where(s => s.ProgressPercent > 0)
            .OrderByDescending(s => s.ProgressPercent)
            .ThenBy(s => s.SkillName, StringComparer.Ordinal)
            .ThenBy(s => s.SkillId)
            .Take(3)
            .Select(s => new SkillProgressSnapshot
            {
                SkillId = s.SkillId,
                SkillName = s.SkillName,
                Category = s.Category,
                ProgressPercent = s.ProgressPercent,
                TotalContentCount = s.TotalContentCount,
                CompletedContentCount = s.CompletedContentCount,
                TotalQuizCount = s.TotalQuizCount,
                AttemptedQuizCount = s.AttemptedQuizCount
            })
            .ToList();

        var focus = skillProgress
            .Where(s => s.TotalContentCount > 0 || s.TotalQuizCount > 0)
            .OrderBy(s => s.ProgressPercent)
            .ThenBy(s => s.SkillName, StringComparer.Ordinal)
            .ThenBy(s => s.SkillId)
            .Take(3)
            .Select(s => new SkillProgressSnapshot
            {
                SkillId = s.SkillId,
                SkillName = s.SkillName,
                Category = s.Category,
                ProgressPercent = s.ProgressPercent,
                TotalContentCount = s.TotalContentCount,
                CompletedContentCount = s.CompletedContentCount,
                TotalQuizCount = s.TotalQuizCount,
                AttemptedQuizCount = s.AttemptedQuizCount
            })
            .ToList();

        return new ProgressSkills
        {
            TotalCount = totalCount,
            StartedCount = startedCount,
            Strongest = strongest,
            Focus = focus
        };
    }

    private async Task<(List<SkillProgressResponse> SkillProgress, List<ContentSkill> ContentSkills)>
        LoadSkillProgressAsync(
            Guid userId,
            Guid specializationId,
            IReadOnlyList<UserContentProgress> contentProgress)
    {
        var skills = await _skillRepository.GetActiveBySpecializationAsync(specializationId);

        if (skills.Count == 0)
        {
            return (new List<SkillProgressResponse>(), new List<ContentSkill>());
        }

        var skillIds = skills.Select(s => s.Id).ToList();

        var contentSkills = await _skillRepository.GetActiveContentLinksAsync(skillIds);
        var quizzes = await _skillRepository.GetActiveQuizzesAsync(skillIds);

        var quizAttempts = quizzes.Count == 0
            ? new List<QuizAttempt>()
            : await _skillRepository.GetUserQuizAttemptsAsync(
                userId,
                quizzes.Select(q => q.Id).ToList());

        var skillProgress = SkillProgressEngine.Calculate(
            userId,
            skills,
            contentSkills,
            contentProgress,
            quizzes,
            quizAttempts);

        return (skillProgress, contentSkills);
    }
}