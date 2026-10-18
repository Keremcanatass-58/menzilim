using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class UserProgressRepository : IUserProgressRepository
{
    private readonly MenzilimDbContext _dbContext;

    public UserProgressRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<UserProgress?> GetByUserAsync(Guid userId)
    {
        return await _dbContext.UserProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId);
    }

    public async Task AddAsync(UserProgress progress)
    {
        await _dbContext.UserProgresses.AddAsync(progress);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
