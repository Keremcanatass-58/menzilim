using Menzilim.Application.DTOs.Dashboard;

namespace Menzilim.Application.Interfaces.Dashboard;

public interface IDashboardService
{
    Task<DashboardResponse?> GetAsync(Guid userId);
}
