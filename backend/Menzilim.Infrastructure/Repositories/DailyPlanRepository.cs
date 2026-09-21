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
        return await WithTaskDetails(_dbContext.DailyPlans)
            .FirstOrDefaultAsync(
                dp => dp.UserId == userId &&
                      dp.Date.Date == date.Date);
    }

    public async Task<DailyTask?> GetTaskByIdAsync(
        Guid taskId)
    {
        // Planın tüm görevleri de yüklenir; aksi halde plan tamamlanma durumu
        // yalnızca bu görevle hesaplanır ve yanıt tek görev döndürür.
        return await _dbContext.DailyTasks
            .Include(dt => dt.DailyPlan)
                .ThenInclude(dp => dp.Tasks)
                    .ThenInclude(t => t.UserProjectStep)
                        .ThenInclude(s => s!.UserProject)
            .Include(dt => dt.DailyPlan)
                .ThenInclude(dp => dp.Tasks)
                    .ThenInclude(t => t.UserProjectStep)
                        .ThenInclude(s => s!.LearningItem)
                            .ThenInclude(i => i.Skill)
            .FirstOrDefaultAsync(dt => dt.Id == taskId);
    }

    public async Task AddAsync(DailyPlan dailyPlan)
    {
        await _dbContext.DailyPlans.AddAsync(dailyPlan);
    }

    public async Task<List<DailyPlan>> GetAllByUserAsync(Guid userId)
    {
        return await _dbContext.DailyPlans
            .Include(dp => dp.Tasks)
            .Where(dp => dp.UserId == userId)
            .OrderByDescending(dp => dp.Date)
            .ToListAsync();
    }

    public async Task<List<DailyTask>> GetTasksByProjectStepAsync(
        Guid userProjectStepId)
    {
        // Planın tüm görevleri de yüklenir; plan tamamlanma durumu ancak
        // tüm görevler bilinince doğru hesaplanır.
        return await _dbContext.DailyTasks
            .Include(dt => dt.DailyPlan)
                .ThenInclude(dp => dp.Tasks)
            .Where(dt => dt.UserProjectStepId == userProjectStepId)
            .ToListAsync();
    }

    /// <summary>
    /// Görevlerin proje adımı, projesi ve becerisi tek sorguda yüklenir;
    /// yanıt bu bilgileri taşır (N+1 yok).
    /// </summary>
    private static IQueryable<DailyPlan> WithTaskDetails(IQueryable<DailyPlan> query)
    {
        return query
            .Include(dp => dp.Tasks)
                .ThenInclude(t => t.UserProjectStep)
                    .ThenInclude(s => s!.UserProject)
            .Include(dp => dp.Tasks)
                .ThenInclude(t => t.UserProjectStep)
                    .ThenInclude(s => s!.LearningItem)
                        .ThenInclude(i => i.Skill);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
