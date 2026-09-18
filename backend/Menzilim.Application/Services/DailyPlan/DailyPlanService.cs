using Menzilim.Application.DTOs.DailyPlan;
using Menzilim.Application.Interfaces.DailyPlan;
using Menzilim.Application.Interfaces.Repositories;

namespace Menzilim.Application.Services.DailyPlan;

public class DailyPlanService : IDailyPlanService
{
    private readonly IDailyPlanRepository _dailyPlanRepository;
    private readonly IUserRepository _userRepository;
    private readonly IUserContentProgressRepository _contentProgressRepository;
    private readonly IQuizRepository _quizRepository;
    private readonly IContentRepository _contentRepository;

    public DailyPlanService(
        IDailyPlanRepository dailyPlanRepository,
        IUserRepository userRepository,
        IUserContentProgressRepository contentProgressRepository,
        IQuizRepository quizRepository,
        IContentRepository contentRepository)
    {
        _dailyPlanRepository = dailyPlanRepository;
        _userRepository = userRepository;
        _contentProgressRepository = contentProgressRepository;
        _quizRepository = quizRepository;
        _contentRepository = contentRepository;
    }

    public async Task<DailyPlanResponse> GetTodayAsync(
        Guid userId)
    {
        var today = DateTime.UtcNow.Date;

        var existing =
            await _dailyPlanRepository
                .GetByUserAndDateAsync(userId, today);

        if (existing is not null)
        {
            // Aynı gün için plan zaten var: yeniden üretmeden mevcut planı kullan.
            return MapToResponse(existing);
        }

        var context = await BuildContextAsync(userId);
        var plan = BuildPlan(userId, today, context);

        await _dailyPlanRepository.AddAsync(plan);
        await _dailyPlanRepository.SaveChangesAsync();

        return MapToResponse(plan);
    }

    public async Task<DailyPlanResponse> CompleteTaskAsync(
        Guid userId,
        Guid taskId)
    {
        var task =
            await _dailyPlanRepository
                .GetTaskByIdAsync(taskId);

        if (task is null)
        {
            throw new InvalidOperationException(
                "Görev bulunamadı.");
        }

        if (task.DailyPlan.UserId != userId)
        {
            throw new UnauthorizedAccessException(
                "Bu göreve erişim yetkiniz yok.");
        }

        if (!task.IsCompleted)
        {
            task.IsCompleted = true;
            task.CompletedAt = DateTime.UtcNow;
        }

        var allTasks = task.DailyPlan.Tasks;

        task.DailyPlan.IsCompleted =
            allTasks.Count > 0 &&
            allTasks.All(t => t.IsCompleted);

        await _dailyPlanRepository.SaveChangesAsync();

        return MapToResponse(task.DailyPlan);
    }

    private async Task<DailyPlanGenerationContext> BuildContextAsync(
        Guid userId)
    {
        var user =
            await _userRepository.GetByIdWithProfileDetailsAsync(userId);
        var profile = user?.Profile;

        var contentProgress =
            await _contentProgressRepository.GetByUserAsync(userId);
        var quizAttemptCount =
            await _quizRepository.GetAttemptCountByUserAsync(userId);

        var professionContent = profile is null
            ? new List<Menzilim.Domain.Content>()
            : await _contentRepository.GetByProfessionAsync(profile.ProfessionId);

        var selection = DailyPlanContentSelector.Select(
            professionContent,
            contentProgress,
            profile?.Specialization?.Name);

        return new DailyPlanGenerationContext
        {
            ProfessionName = profile?.Profession?.Name ?? string.Empty,
            SpecializationName = profile?.Specialization?.Name ?? string.Empty,
            ExperienceLevel = profile?.ExperienceLevel ?? string.Empty,
            CareerGoal = profile?.CareerGoal ?? string.Empty,
            DailyLearningMinutes = profile?.DailyLearningMinutes ?? 0,
            CompletedContentCount =
                contentProgress.Count(c => c.IsCompleted),
            InProgressContentCount =
                contentProgress.Count(c => !c.IsCompleted),
            QuizAttemptCount = quizAttemptCount,
            LearnContentId = selection.ContentId,
            LearnContentTitle = selection.Title,
            LearnContentIsContinuation = selection.IsContinuation,
        };
    }

    private static Menzilim.Domain.DailyPlan BuildPlan(
        Guid userId,
        DateTime date,
        DailyPlanGenerationContext context)
    {
        var plan = new Menzilim.Domain.DailyPlan
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Date = date,
            Title = DailyPlanGenerator.BuildPlanTitle(context),
            IsCompleted = false,
            CreatedAt = DateTime.UtcNow,
        };

        foreach (var task in DailyPlanGenerator.Generate(context))
        {
            plan.Tasks.Add(
                new Menzilim.Domain.DailyTask
                {
                    Id = Guid.NewGuid(),
                    DailyPlanId = plan.Id,
                    Title = task.Title,
                    Description = task.Description,
                    TaskType = task.TaskType,
                    EstimatedMinutes = task.EstimatedMinutes,
                    IsCompleted = false,
                    ContentId = task.ContentId,
                });
        }

        return plan;
    }

    private static DailyPlanResponse MapToResponse(
        Menzilim.Domain.DailyPlan dailyPlan)
    {
        var tasks = dailyPlan.Tasks
            .Select(task => new DailyTaskResponse
            {
                Id = task.Id,
                Title = task.Title,
                Description = task.Description,
                TaskType = task.TaskType,
                EstimatedMinutes = task.EstimatedMinutes,
                IsCompleted = task.IsCompleted,
                CompletedAt = task.CompletedAt,
                ContentId = task.ContentId
            })
            .ToList();

        return new DailyPlanResponse
        {
            Id = dailyPlan.Id,
            Date = dailyPlan.Date,
            Title = dailyPlan.Title,
            IsCompleted = dailyPlan.IsCompleted,
            TotalMinutes =
                tasks.Sum(task => task.EstimatedMinutes),
            CompletedMinutes =
                tasks
                    .Where(task => task.IsCompleted)
                    .Sum(task => task.EstimatedMinutes),
            Tasks = tasks
        };
    }
}
