using Menzilim.Application.DTOs.Projects;
using Menzilim.Application.Interfaces.Projects;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Projects;

/// <summary>
/// Living Project: kullanıcının uzmanlığına bağlı proje şablonunu kendi
/// projesine dönüştürür ve adım ilerlemesini yönetir. AI kullanmaz.
/// </summary>
public class UserProjectService : IUserProjectService
{
    private readonly IUserProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;
    private readonly IUserContentProgressRepository _contentProgressRepository;

    // Adım tamamlanınca ona bağlı günlük görev de tamamlanır.
    private readonly IDailyPlanRepository? _dailyPlanRepository;

    public UserProjectService(
        IUserProjectRepository projectRepository,
        IUserRepository userRepository,
        IUserContentProgressRepository contentProgressRepository,
        IDailyPlanRepository? dailyPlanRepository = null)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
        _contentProgressRepository = contentProgressRepository;
        _dailyPlanRepository = dailyPlanRepository;
    }

    public async Task<List<UserProjectResponse>> GetMyProjectsAsync(Guid userId)
    {
        await EnsureProjectAsync(userId);

        var projects = await _projectRepository.GetByUserAsync(userId);

        return projects
            .OrderBy(p => p.CreatedAt)
            .Select(Map)
            .ToList();
    }

    public async Task<UserProjectResponse?> GetByIdAsync(
        Guid userId,
        Guid projectId)
    {
        var project = await _projectRepository.GetByIdAsync(projectId);

        // Başka kullanıcının projesi de bulunamadı sayılır.
        if (project is null || project.UserId != userId)
        {
            return null;
        }

        return Map(project);
    }

    public async Task<UserProjectResponse?> CompleteStepAsync(
        Guid userId,
        Guid stepId)
    {
        var step = await _projectRepository.GetStepWithProjectAsync(stepId);

        if (step is null || step.UserProject.UserId != userId)
        {
            return null;
        }

        if (step.Status == UserProjectStepStatus.Locked)
        {
            throw new InvalidOperationException(
                "Bu adım henüz açılmadı. Önceki adımı tamamla.");
        }

        var project = step.UserProject;

        if (step.Status != UserProjectStepStatus.Completed)
        {
            step.Status = UserProjectStepStatus.Completed;
            step.CompletedAt = DateTime.UtcNow;

            // Sıradaki kilitli adım açılır.
            var next = project.Steps
                .Where(s => s.Order > step.Order)
                .OrderBy(s => s.Order)
                .FirstOrDefault();

            if (next is not null &&
                next.Status == UserProjectStepStatus.Locked)
            {
                next.Status = UserProjectStepStatus.Available;
            }

            project.StartedAt ??= DateTime.UtcNow;

            var allCompleted = project.Steps
                .All(s => s.Status == UserProjectStepStatus.Completed);

            if (allCompleted)
            {
                project.Status = UserProjectStatus.Completed;
                project.CompletedAt ??= DateTime.UtcNow;
            }
            else
            {
                project.Status = UserProjectStatus.InProgress;
            }

            await _projectRepository.SaveChangesAsync();

            // İçerikli adımlar içerik ilerlemesiyle senkron kalır: beceri
            // ilerlemesi ve günlük plan mevcut sistemden hesaplanmaya devam eder.
            await SyncContentProgressAsync(userId, step.LearningItem.ContentId);

            // Adım authoritative kaynaktır: ona bağlı görev de tamamlanır.
            await SyncDailyTaskAsync(userId, step.Id);
        }

        var refreshed = await _projectRepository.GetByIdAsync(project.Id);

        return refreshed is null ? null : Map(refreshed);
    }

    /// <summary>
    /// Kullanıcının uzmanlığına bağlı şablondan projeyi bir kez oluşturur.
    /// Şablon yoksa (ör. içerik hazırlanmamış uzmanlık) sessizce atlanır.
    /// </summary>
    private async Task EnsureProjectAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user?.Profile is null)
        {
            throw new KeyNotFoundException("Kullanıcı profili bulunamadı.");
        }

        var template = await _projectRepository
            .GetTemplateBySpecializationAsync(user.Profile.SpecializationId);

        if (template is null || template.Items.Count == 0)
        {
            return;
        }

        var existing = await _projectRepository.GetByUserAsync(userId);

        if (existing.Any(p => p.LearningPathId == template.Id))
        {
            return;
        }

        var project = new UserProject
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            LearningPathId = template.Id,
            Name = template.Title,
            Description = template.Description,
            Status = UserProjectStatus.NotStarted,
            CreatedAt = DateTime.UtcNow
        };

        var ordered = template.Items
            .OrderBy(i => i.Order)
            .ToList();

        for (var index = 0; index < ordered.Count; index++)
        {
            var item = ordered[index];

            project.Steps.Add(new UserProjectStep
            {
                Id = Guid.NewGuid(),
                UserProjectId = project.Id,
                LearningItemId = item.Id,
                Order = item.Order,
                // Yalnızca ilk adım açık başlar.
                Status = index == 0
                    ? UserProjectStepStatus.Available
                    : UserProjectStepStatus.Locked
            });
        }

        await _projectRepository.AddAsync(project);
        await _projectRepository.SaveChangesAsync();
    }

    private async Task SyncContentProgressAsync(Guid userId, Guid? contentId)
    {
        if (contentId is null)
        {
            return;
        }

        var progress = await _contentProgressRepository.GetAsync(
            userId,
            contentId.Value);

        if (progress is null)
        {
            progress = new UserContentProgress
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ContentId = contentId.Value,
                StartedAt = DateTime.UtcNow
            };

            await _contentProgressRepository.AddAsync(progress);
        }

        if (!progress.IsCompleted)
        {
            progress.IsCompleted = true;
            progress.CompletedAt ??= DateTime.UtcNow;
        }

        await _contentProgressRepository.SaveChangesAsync();
    }

    /// <summary>
    /// Adıma bağlı günlük görevleri tamamlar ve gerekirse planı tamamlanmış
    /// işaretler. Tersi yapılmaz: görev tamamlanması adımı tamamlamaz.
    /// </summary>
    private async Task SyncDailyTaskAsync(Guid userId, Guid stepId)
    {
        if (_dailyPlanRepository is null)
        {
            return;
        }

        var tasks = await _dailyPlanRepository.GetTasksByProjectStepAsync(stepId);

        var changed = false;

        foreach (var task in tasks)
        {
            // Yalnızca kullanıcının kendi planındaki görevler.
            if (task.DailyPlan.UserId != userId || task.IsCompleted)
            {
                continue;
            }

            task.IsCompleted = true;
            task.CompletedAt = DateTime.UtcNow;
            changed = true;
        }

        if (!changed)
        {
            return;
        }

        foreach (var plan in tasks
            .Select(t => t.DailyPlan)
            .Where(p => p.UserId == userId)
            .DistinctBy(p => p.Id))
        {
            plan.IsCompleted =
                plan.Tasks.Count > 0 && plan.Tasks.All(t => t.IsCompleted);
        }

        await _dailyPlanRepository.SaveChangesAsync();
    }

    private static UserProjectResponse Map(UserProject project)
    {
        var steps = project.Steps
            .OrderBy(s => s.Order)
            .Select(MapStep)
            .ToList();

        var completed = steps
            .Count(s => s.Status == UserProjectStepStatus.Completed);

        var percent = steps.Count == 0
            ? 0
            : (int)Math.Round((double)completed / steps.Count * 100);

        return new UserProjectResponse
        {
            Id = project.Id,
            Name = project.Name,
            Description = project.Description,
            Status = project.Status,
            TotalSteps = steps.Count,
            CompletedSteps = completed,
            ProgressPercent = percent,
            TotalMinutes = steps.Sum(s => s.EstimatedMinutes),
            StartedAt = project.StartedAt,
            CompletedAt = project.CompletedAt,
            NextStep = steps.FirstOrDefault(
                s => s.Status == UserProjectStepStatus.Available),
            Steps = steps
        };
    }

    private static UserProjectStepResponse MapStep(UserProjectStep step)
    {
        var item = step.LearningItem;

        return new UserProjectStepResponse
        {
            Id = step.Id,
            Order = step.Order,
            Title = item?.Title ?? string.Empty,
            Description = item?.Description,
            Status = step.Status,
            EstimatedMinutes = item?.EstimatedMinutes ?? 0,
            ContentId = item?.ContentId,
            ContentTitle = item?.Content?.Title,
            SkillId = item?.SkillId,
            SkillName = item?.Skill?.Name,
            CompletedAt = step.CompletedAt,
            EvidenceUrl = step.EvidenceUrl,
            Note = step.Note
        };
    }
}
