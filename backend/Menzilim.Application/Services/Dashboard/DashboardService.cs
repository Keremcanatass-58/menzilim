using Menzilim.Application.DTOs.Dashboard;
using Menzilim.Application.Interfaces.Dashboard;
using Menzilim.Application.Interfaces.Repositories;

namespace Menzilim.Application.Services.Dashboard;

public class DashboardService : IDashboardService
{
    private readonly IUserRepository _userRepository;
    private readonly IDailyPlanRepository _dailyPlanRepository;
    private readonly IUserContentProgressRepository _contentProgressRepository;

    public DashboardService(
        IUserRepository userRepository,
        IDailyPlanRepository dailyPlanRepository,
        IUserContentProgressRepository contentProgressRepository)
    {
        _userRepository = userRepository;
        _dailyPlanRepository = dailyPlanRepository;
        _contentProgressRepository = contentProgressRepository;
    }

    public async Task<DashboardResponse?> GetAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user?.Profile is null)
            return null;

        var profile = user.Profile;

        // Günlük plan ilerlemesi
        var today = DateTime.UtcNow.Date;
        var dailyPlan = await _dailyPlanRepository.GetByUserAndDateAsync(userId, today);

        int totalTasks = 0;
        int completedTasks = 0;
        int totalMinutes = 0;
        int completedMinutes = 0;
        double dailyProgressPercent = 0;

        if (dailyPlan is not null)
        {
            var tasks = dailyPlan.Tasks;
            totalTasks = tasks.Count;
            completedTasks = tasks.Count(t => t.IsCompleted);
            totalMinutes = tasks.Sum(t => t.EstimatedMinutes);
            completedMinutes = tasks.Where(t => t.IsCompleted).Sum(t => t.EstimatedMinutes);
            dailyProgressPercent = totalMinutes > 0
                ? Math.Round((double)completedMinutes / totalMinutes * 100, 1)
                : 0;
        }

        // İçerik ilerlemesi
        var contentProgresses = await _contentProgressRepository.GetByUserAsync(userId);
        int completedContentCount = contentProgresses.Count(cp => cp.IsCompleted);
        int inProgressContentCount = contentProgresses.Count(cp => !cp.IsCompleted);

        return new DashboardResponse
        {
            UserId = user.Id,
            Profession = profile.Profession.Name,
            Specialization = profile.Specialization.Name,
            ExperienceLevel = profile.ExperienceLevel,
            CareerGoal = profile.CareerGoal,
            DailyLearningMinutes = profile.DailyLearningMinutes,
            TotalTasks = totalTasks,
            CompletedTasks = completedTasks,
            TotalMinutes = totalMinutes,
            CompletedMinutes = completedMinutes,
            DailyProgressPercent = dailyProgressPercent,
            CompletedContentCount = completedContentCount,
            InProgressContentCount = inProgressContentCount
        };
    }
}
