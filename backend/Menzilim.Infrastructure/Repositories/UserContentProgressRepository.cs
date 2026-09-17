using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class UserContentProgressRepository : IUserContentProgressRepository
{
    private readonly MenzilimDbContext _dbContext;

    public UserContentProgressRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<UserContentProgress?> GetAsync(Guid userId, Guid contentId)
    {
        return await _dbContext.UserContentProgresses
            .FirstOrDefaultAsync(x => x.UserId == userId && x.ContentId == contentId);
    }

    public async Task<List<UserContentProgress>> GetByUserAsync(Guid userId)
    {
        return await _dbContext.UserContentProgresses
            .Where(x => x.UserId == userId)
            .ToListAsync();
    }

    public async Task AddAsync(UserContentProgress progress)
    {
        await _dbContext.UserContentProgresses.AddAsync(progress);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
