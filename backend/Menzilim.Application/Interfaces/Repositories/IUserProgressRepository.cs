using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface IUserProgressRepository
{
    Task<UserProgress?> GetByUserAsync(Guid userId);

    Task AddAsync(UserProgress progress);

    Task SaveChangesAsync();
}
