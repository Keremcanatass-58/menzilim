using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly MenzilimDbContext _dbContext;

    public UserRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _dbContext.Users
            .FirstOrDefaultAsync(u => u.Email == email);
    }

    public async Task<User?> GetByIdAsync(Guid id)
    {
        return await _dbContext.Users
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<User?> GetByIdWithProfileDetailsAsync(Guid id)
    {
        return await _dbContext.Users
            .Include(u => u.Profile)
                .ThenInclude(p => p!.Profession)
            .Include(u => u.Profile)
                .ThenInclude(p => p!.Specialization)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task AddAsync(User user)
    {
        await _dbContext.Users.AddAsync(user);
    }

    public async Task AddProfileAsync(UserProfile profile)
    {
        await _dbContext.UserProfiles.AddAsync(profile);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
