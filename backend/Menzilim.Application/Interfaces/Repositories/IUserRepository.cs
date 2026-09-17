using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface IUserRepository
{
    Task<User?> GetByEmailAsync(string email);

    Task<User?> GetByIdAsync(Guid id);

    Task<User?> GetByIdWithProfileDetailsAsync(Guid id);

    Task AddAsync(User user);

    Task AddProfileAsync(UserProfile profile);

    Task SaveChangesAsync();
}
