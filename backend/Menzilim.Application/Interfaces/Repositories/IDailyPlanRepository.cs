using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface IDailyPlanRepository
{
    Task<Menzilim.Domain.DailyPlan?> GetByUserAndDateAsync(
        Guid userId,
        DateTime date);

    Task<DailyTask?> GetTaskByIdAsync(
        Guid taskId);

    Task AddAsync(Menzilim.Domain.DailyPlan dailyPlan);

    Task<List<Menzilim.Domain.DailyPlan>> GetAllByUserAsync(Guid userId);

    /// <summary>Bir proje adımına bağlı günlük görevler (tüm günler).</summary>
    Task<List<DailyTask>> GetTasksByProjectStepAsync(Guid userProjectStepId);

    Task SaveChangesAsync();
}