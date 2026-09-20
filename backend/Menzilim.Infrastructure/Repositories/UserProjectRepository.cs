using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class UserProjectRepository : IUserProjectRepository
{
    private readonly MenzilimDbContext _dbContext;

    public UserProjectRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<UserProject>> GetByUserAsync(Guid userId)
    {
        return await WithDetails()
            .Where(p => p.UserId == userId)
            .ToListAsync();
    }

    public async Task<UserProject?> GetByIdAsync(Guid projectId)
    {
        return await WithDetails()
            .FirstOrDefaultAsync(p => p.Id == projectId);
    }

    public async Task<UserProjectStep?> GetStepWithProjectAsync(Guid stepId)
    {
        return await _dbContext.UserProjectSteps
            .Include(s => s.LearningItem)
            .Include(s => s.UserProject)
                .ThenInclude(p => p.Steps)
                    .ThenInclude(s => s.LearningItem)
            .FirstOrDefaultAsync(s => s.Id == stepId);
    }

    public async Task<LearningPath?> GetTemplateBySpecializationAsync(
        Guid specializationId)
    {
        return await _dbContext.LearningPaths
            .Include(p => p.Items)
            .Where(p => p.IsActive && p.SpecializationId == specializationId)
            .OrderBy(p => p.CreatedAt)
            .FirstOrDefaultAsync();
    }

    public async Task AddAsync(UserProject project)
    {
        await _dbContext.UserProjects.AddAsync(project);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }

    private IQueryable<UserProject> WithDetails()
    {
        return _dbContext.UserProjects
            .Include(p => p.LearningPath)
            .Include(p => p.Steps)
                .ThenInclude(s => s.LearningItem)
                    .ThenInclude(i => i.Content)
            .Include(p => p.Steps)
                .ThenInclude(s => s.LearningItem)
                    .ThenInclude(i => i.Skill);
    }
}
