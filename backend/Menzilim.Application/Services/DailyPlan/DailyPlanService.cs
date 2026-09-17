using Menzilim.Application.DTOs.DailyPlan;
using Menzilim.Application.Interfaces.DailyPlan;
using Menzilim.Application.Interfaces.Repositories;

namespace Menzilim.Application.Services.DailyPlan;

public class DailyPlanService : IDailyPlanService
{
    private readonly IDailyPlanRepository _dailyPlanRepository;

    public DailyPlanService(
        IDailyPlanRepository dailyPlanRepository)
    {
        _dailyPlanRepository = dailyPlanRepository;
    }

    public async Task<DailyPlanResponse> GetTodayAsync(
        Guid userId)
    {
        var today = DateTime.UtcNow.Date;

        var dailyPlan =
            await _dailyPlanRepository
                .GetByUserAndDateAsync(userId, today);

        if (dailyPlan is null)
        {
            dailyPlan = CreateDefaultPlan(userId, today);

            await _dailyPlanRepository.AddAsync(dailyPlan);
            await _dailyPlanRepository.SaveChangesAsync();
        }
        else
        {
            var changed = EnsureDefaultTasks(dailyPlan);

            if (changed)
            {
                await _dailyPlanRepository.SaveChangesAsync();
            }
        }

        return MapToResponse(dailyPlan);
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

    private static bool EnsureDefaultTasks(
        Menzilim.Domain.DailyPlan dailyPlan)
    {
        var changed = false;

        if (!dailyPlan.Tasks.Any(t => t.TaskType == "Learn"))
        {
            dailyPlan.Tasks.Add(
                new Menzilim.Domain.DailyTask
                {
                    Id = Guid.NewGuid(),
                    DailyPlanId = dailyPlan.Id,
                    Title = "Bugünün Konusunu Öğren",
                    Description =
                        "Kariyer hedefin doğrultusunda bugünün konusunu öğren.",
                    TaskType = "Learn",
                    EstimatedMinutes = 25,
                    IsCompleted = false
                });

            changed = true;
        }

        if (!dailyPlan.Tasks.Any(t => t.TaskType == "Practice"))
        {
            dailyPlan.Tasks.Add(
                new Menzilim.Domain.DailyTask
                {
                    Id = Guid.NewGuid(),
                    DailyPlanId = dailyPlan.Id,
                    Title = "Uygulama Yap",
                    Description =
                        "Öğrendiğin konuyla ilgili küçük bir uygulama gerçekleştir.",
                    TaskType = "Practice",
                    EstimatedMinutes = 20,
                    IsCompleted = false
                });

            changed = true;
        }

        if (!dailyPlan.Tasks.Any(t => t.TaskType == "Quiz"))
        {
            dailyPlan.Tasks.Add(
                new Menzilim.Domain.DailyTask
                {
                    Id = Guid.NewGuid(),
                    DailyPlanId = dailyPlan.Id,
                    Title = "Bilgini Test Et",
                    Description =
                        "Bugün öğrendiklerini kısa bir test ile kontrol et.",
                    TaskType = "Quiz",
                    EstimatedMinutes = 15,
                    IsCompleted = false
                });

            changed = true;
        }

        return changed;
    }

    private static Menzilim.Domain.DailyPlan CreateDefaultPlan(
        Guid userId,
        DateTime date)
    {
        var plan = new Menzilim.Domain.DailyPlan
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Date = date,
            Title = "Bugünün Öğrenme Planı",
            IsCompleted = false,
            CreatedAt = DateTime.UtcNow
        };

        plan.Tasks.Add(
            new Menzilim.Domain.DailyTask
            {
                Id = Guid.NewGuid(),
                DailyPlanId = plan.Id,
                Title = "Bugünün Konusunu Öğren",
                Description =
                    "Kariyer hedefin doğrultusunda bugünün konusunu öğren.",
                TaskType = "Learn",
                EstimatedMinutes = 25,
                IsCompleted = false
            });

        plan.Tasks.Add(
            new Menzilim.Domain.DailyTask
            {
                Id = Guid.NewGuid(),
                DailyPlanId = plan.Id,
                Title = "Uygulama Yap",
                Description =
                    "Öğrendiğin konuyla ilgili küçük bir uygulama gerçekleştir.",
                TaskType = "Practice",
                EstimatedMinutes = 20,
                IsCompleted = false
            });

        plan.Tasks.Add(
            new Menzilim.Domain.DailyTask
            {
                Id = Guid.NewGuid(),
                DailyPlanId = plan.Id,
                Title = "Bilgini Test Et",
                Description =
                    "Bugün öğrendiklerini kısa bir test ile kontrol et.",
                TaskType = "Quiz",
                EstimatedMinutes = 15,
                IsCompleted = false
            });

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
                CompletedAt = task.CompletedAt
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
