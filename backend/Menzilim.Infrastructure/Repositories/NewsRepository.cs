using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class NewsRepository : INewsRepository
{
    private readonly MenzilimDbContext _dbContext;

    public NewsRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<NewsItem>> GetActiveBySpecializationAsync(
        Guid specializationId,
        int take)
    {
        var skillIds = _dbContext.SpecializationSkills
            .Where(ss =>
                ss.SpecializationId == specializationId &&
                ss.Skill.IsActive)
            .Select(ss => ss.SkillId);

        return await QueryBySkills(skillIds, take);
    }

    public async Task<List<NewsItem>> GetActiveByProfessionAsync(
        Guid professionId,
        int take)
    {
        var skillIds = _dbContext.SpecializationSkills
            .Where(ss =>
                ss.Specialization.ProfessionId == professionId &&
                ss.Specialization.IsActive &&
                ss.Skill.IsActive)
            .Select(ss => ss.SkillId);

        return await QueryBySkills(skillIds, take);
    }

    // Tek sorgu: skill alt sorgusu EXISTS/IN olarak çevrilir; N+1 yok.
    private Task<List<NewsItem>> QueryBySkills(
        IQueryable<Guid> skillIds,
        int take)
    {
        return _dbContext.NewsItems
            .AsNoTracking()
            .Where(n =>
                n.IsActive &&
                n.Skills.Any(ns => skillIds.Contains(ns.SkillId)))
            .OrderByDescending(n => n.PublishedAt)
            .ThenBy(n => n.Id)
            .Take(take)
            .ToListAsync();
    }
}
