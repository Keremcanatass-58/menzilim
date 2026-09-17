using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class DailyPlanRepository : IDailyPlanRepository
{
    private readonly MenzilimDbContext _dbContext;

    public DailyPlanRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<DailyPlan?> GetByUserAndDateAsync(
        Guid userId,
        DateTime date)
    {
        return await _dbContext.DailyPlans
            .Include(dp => dp.Tasks)
            .FirstOrDefaultAsync(
                dp => dp.UserId == userId &&
                      dp.Date.Date == date.Date);
    }

    public async Task<DailyTask?> GetTaskByIdAsync(
        Guid taskId)
    {
        return await _dbContext.DailyTasks
            .Include(dt => dt.DailyPlan)
            .FirstOrDefaultAsync(dt => dt.Id == taskId);
    }

    public async Task AddAsync(DailyPlan dailyPlan)
    {
        await _dbContext.DailyPlans.AddAsync(dailyPlan);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
