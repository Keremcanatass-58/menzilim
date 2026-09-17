using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface IUserContentProgressRepository
{
    Task<UserContentProgress?> GetAsync(Guid userId, Guid contentId);
    Task<List<UserContentProgress>> GetByUserAsync(Guid userId);
    Task AddAsync(UserContentProgress progress);
    Task SaveChangesAsync();
}
