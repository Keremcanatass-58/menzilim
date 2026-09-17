using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class ContentRepository : IContentRepository
{
    private readonly MenzilimDbContext _dbContext;

    public ContentRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<Content>> GetActiveAsync()
    {
        return await _dbContext.Contents
            .Where(content => content.IsActive)
            .OrderByDescending(content => content.PublishedAt)
            .ToListAsync();
    }

    public async Task<Content?> GetByIdAsync(Guid contentId)
    {
        return await _dbContext.Contents
            .FirstOrDefaultAsync(content =>
                content.Id == contentId &&
                content.IsActive);
    }

    public async Task<List<Content>> GetByProfessionAsync(
        Guid professionId)
    {
        return await _dbContext.ContentProfessions
            .Where(cp =>
                cp.ProfessionId == professionId &&
                cp.Content.IsActive)
            .Include(cp => cp.Content)
            .Select(cp => cp.Content)
            .OrderByDescending(content => content.PublishedAt)
            .ToListAsync();
    }

    public async Task AddAsync(Content content)
    {
        await _dbContext.Contents.AddAsync(content);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
