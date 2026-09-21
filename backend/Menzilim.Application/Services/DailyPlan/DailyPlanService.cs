using Menzilim.Application.DTOs.DailyPlan;
using Menzilim.Application.DTOs.Projects;
using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Interfaces.Projects;
using Menzilim.Application.Interfaces.DailyPlan;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Services.Skills;
using Menzilim.Domain;

namespace Menzilim.Application.Services.DailyPlan;

public class DailyPlanService : IDailyPlanService
{
    // Learn + (varsa) Practice için en fazla iki farklı içerik seçilir.
    private const int ContentSlotCount = 2;

    private readonly IDailyPlanRepository _dailyPlanRepository;
    private readonly IUserRepository _userRepository;
    private readonly IUserContentProgressRepository _contentProgressRepository;
    private readonly IQuizRepository _quizRepository;
    private readonly IContentRepository _contentRepository;
    private readonly ISkillRepository _skillRepository;

    // Projesi olmayan kullanıcılarda null kalır; plan eskisi gibi üretilir.
    private readonly IUserProjectService? _userProjectService;

    public DailyPlanService(
        IDailyPlanRepository dailyPlanRepository,
        IUserRepository userRepository,
        IUserContentProgressRepository contentProgressRepository,
        IQuizRepository quizRepository,
        IContentRepository contentRepository,
        ISkillRepository skillRepository,
        IUserProjectService? userProjectService = null)
    {
        _dailyPlanRepository = dailyPlanRepository;
        _userRepository = userRepository;
        _contentProgressRepository = contentProgressRepository;
        _quizRepository = quizRepository;
        _contentRepository = contentRepository;
        _skillRepository = skillRepository;
        _userProjectService = userProjectService;
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
            return MapToResponse(existing, await ResolveQuizIdAsync(userId, existing));
        }

        var context = await BuildContextAsync(userId);
        var plan = BuildPlan(userId, today, context);

        await _dailyPlanRepository.AddAsync(plan);
        await _dailyPlanRepository.SaveChangesAsync();

        return MapToResponse(plan, await ResolveQuizIdAsync(userId, plan));
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

        return MapToResponse(
            task.DailyPlan,
            await ResolveQuizIdAsync(userId, task.DailyPlan));
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

        var (skillProgress, contentSkills) = profile is null
            ? (new List<SkillProgressResponse>(), new List<ContentSkill>())
            : await LoadSkillProgressAsync(
                userId, profile.SpecializationId, contentProgress);

        var selections = DailyPlanSkillContentSelector.Select(
            professionContent,
            contentProgress,
            contentSkills,
            skillProgress,
            profile?.Specialization?.Name,
            ContentSlotCount);

        var learn = selections.ElementAtOrDefault(0);
        var practice = selections.ElementAtOrDefault(1);

        var project = await FindNextProjectStepAsync(userId);

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
            LearnContentId = learn?.ContentId,
            LearnContentTitle = learn?.Title,
            LearnContentIsContinuation = learn?.IsContinuation ?? false,
            LearnFocusSkillName = learn?.FocusSkillName,
            PracticeContentId = practice?.ContentId,
            PracticeContentTitle = practice?.Title,
            PracticeFocusSkillName = practice?.FocusSkillName,
            ProjectStepId = project?.Step.Id,
            ProjectStepTitle = project?.Step.Title,
            ProjectStepDescription = project?.Step.Description,
            ProjectStepOrder = project?.Step.Order ?? 0,
            ProjectTotalSteps = project?.Project.TotalSteps ?? 0,
            ProjectStepMinutes = project?.Step.EstimatedMinutes ?? 0,
            ProjectName = project?.Project.Name,
            ProjectStepContentId = project?.Step.ContentId,
            ProjectStepSkillName = project?.Step.SkillName,
        };
    }

    /// <summary>
    /// Kullanıcının aktif projesindeki sıradaki (Available) adım. Proje henüz
    /// oluşmadıysa servis onu burada oluşturur; böylece kullanıcı Yolum
    /// sekmesini hiç açmasa da günün ana görevi proje adımı olur. Proje ya da
    /// açık adım yoksa null döner ve plan eskisi gibi üretilir.
    /// </summary>
    private async Task<(UserProjectStepResponse Step, UserProjectResponse Project)?>
        FindNextProjectStepAsync(Guid userId)
    {
        if (_userProjectService is null)
        {
            return null;
        }

        List<UserProjectResponse> projects;

        try
        {
            projects = await _userProjectService.GetMyProjectsAsync(userId);
        }
        catch (KeyNotFoundException)
        {
            // Profil yoksa plan zaten kişiselleştirilemez.
            return null;
        }

        foreach (var project in projects.Where(p => p.NextStep is not null))
        {
            return (project.NextStep!, project);
        }

        return null;
    }

    /// <summary>
    /// Kullanıcının uzmanlık skill'lerinin ilerlemesini /api/skills/me ile aynı
    /// kaynaklardan ve aynı engine ile hesaplar. Sabit sayıda sorgu (N+1 yok).
    /// </summary>
    private async Task<(List<SkillProgressResponse> SkillProgress, List<ContentSkill> ContentSkills)>
        LoadSkillProgressAsync(
            Guid userId,
            Guid specializationId,
            IReadOnlyList<UserContentProgress> contentProgress)
    {
        var skills =
            await _skillRepository.GetActiveBySpecializationAsync(specializationId);

        if (skills.Count == 0)
        {
            return (new List<SkillProgressResponse>(), new List<ContentSkill>());
        }

        var skillIds = skills.Select(s => s.Id).ToList();

        var contentSkills =
            await _skillRepository.GetActiveContentLinksAsync(skillIds);
        var quizzes =
            await _skillRepository.GetActiveQuizzesAsync(skillIds);

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

    /// <summary>
    /// Quiz görevinin açacağı quiz'i kullanıcının uzmanlığına göre seçer.
    /// DailyTask'ta quiz kolonu olmadığından seçim yanıt anında yapılır;
    /// seçim yalnızca profile bağlı olduğu için gün içinde sabittir.
    /// Sabit sayıda sorgu (N+1 yok); plan Quiz görevi içermiyorsa hiç sorgu yok.
    /// Uzmanlığa uygun quiz yoksa mevcut varsayılan aktif quiz kullanılır.
    /// </summary>
    private async Task<Guid?> ResolveQuizIdAsync(
        Guid userId,
        Menzilim.Domain.DailyPlan plan)
    {
        if (!plan.Tasks.Any(t => IsQuizTask(t.TaskType)))
        {
            return null;
        }

        var profile =
            (await _userRepository.GetByIdWithProfileDetailsAsync(userId))?.Profile;

        if (profile is not null)
        {
            var skills =
                await _skillRepository.GetActiveBySpecializationAsync(profile.SpecializationId);

            var quizzes = skills.Count == 0
                ? new List<Menzilim.Domain.Quiz>()
                : await _skillRepository.GetActiveQuizzesAsync(
                    skills.Select(s => s.Id).ToList());

            var selected = DailyPlanQuizSelector.Select(
                quizzes,
                profile.Specialization?.Name);

            if (selected is not null)
            {
                return selected.Id;
            }
        }

        var fallback = await _quizRepository.GetFirstActiveWithQuestionsAsync();

        return fallback?.Id;
    }

    private static bool IsQuizTask(string taskType) =>
        string.Equals(taskType, "Quiz", StringComparison.OrdinalIgnoreCase);

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
                    UserProjectStepId = task.UserProjectStepId,
                });
        }

        return plan;
    }

    // DailyTask'ta sıra kolonu yok; veritabanı görevleri sırasız döndürebilir.
    // Kullanıcı sırası DailyPlanGenerator'ın görev tipleriyle aynıdır.
    private static readonly string[] TaskTypeOrder =
        { "Project", "Learn", "Practice", "Quiz", "Review" };

    private static int TaskTypeRank(string taskType)
    {
        var index = Array.FindIndex(
            TaskTypeOrder,
            type => string.Equals(type, taskType, StringComparison.OrdinalIgnoreCase));

        // Bilinmeyen tipler sona.
        return index < 0 ? TaskTypeOrder.Length : index;
    }

    private static DailyPlanResponse MapToResponse(
        Menzilim.Domain.DailyPlan dailyPlan,
        Guid? quizId)
    {
        var tasks = dailyPlan.Tasks
            .OrderBy(task => TaskTypeRank(task.TaskType))
            .ThenBy(task => task.Title, StringComparer.Ordinal)
            .ThenBy(task => task.Id)
            .Select(task => new DailyTaskResponse
            {
                Id = task.Id,
                Title = task.Title,
                Description = task.Description,
                TaskType = task.TaskType,
                EstimatedMinutes = task.EstimatedMinutes,
                IsCompleted = task.IsCompleted,
                CompletedAt = task.CompletedAt,
                ContentId = task.ContentId,
                QuizId = IsQuizTask(task.TaskType) ? quizId : null,
                UserProjectStepId = task.UserProjectStepId,
                UserProjectId = task.UserProjectStep?.UserProjectId,
                ProjectName = task.UserProjectStep?.UserProject?.Name,
                ProjectStepOrder = task.UserProjectStep?.Order,
                ProjectTotalSteps = task.UserProjectStep?.UserProject?.Steps.Count,
                SkillName = task.UserProjectStep?.LearningItem?.Skill?.Name,
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
