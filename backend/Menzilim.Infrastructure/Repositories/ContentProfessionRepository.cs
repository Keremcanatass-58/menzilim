using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class ContentProfessionRepository : IContentProfessionRepository
{
    private readonly MenzilimDbContext _dbContext;

    public ContentProfessionRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<bool> ExistsAsync(
        Guid contentId,
        Guid professionId)
    {
        return await _dbContext.ContentProfessions
            .AnyAsync(cp =>
                cp.ContentId == contentId &&
                cp.ProfessionId == professionId);
    }

    public async Task AddAsync(
        Menzilim.Domain.ContentProfession contentProfession)
    {
        await _dbContext.ContentProfessions.AddAsync(contentProfession);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
