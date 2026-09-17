using Menzilim.Application.DTOs.DailyPlan;

namespace Menzilim.Application.Interfaces.DailyPlan;

public interface IDailyPlanService
{
    Task<DailyPlanResponse> GetTodayAsync(Guid userId);

    Task<DailyPlanResponse> CompleteTaskAsync(
        Guid userId,
        Guid taskId);
}
