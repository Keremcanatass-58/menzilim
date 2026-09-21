using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class SkillRepository : ISkillRepository
{
    private readonly MenzilimDbContext _dbContext;

    public SkillRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<bool> SpecializationExistsAsync(Guid specializationId)
    {
        return await _dbContext.Specializations
            .AnyAsync(s => s.Id == specializationId && s.IsActive);
    }

    public async Task<List<Skill>> GetActiveBySpecializationAsync(
        Guid specializationId)
    {
        return await _dbContext.SpecializationSkills
            .AsNoTracking()
            .Where(ss =>
                ss.SpecializationId == specializationId &&
                ss.Skill.IsActive)
            .Select(ss => ss.Skill)
            .ToListAsync();
    }

    public async Task<List<SpecializationSkill>> GetSpecializationSkillsAsync(
        Guid specializationId)
    {
        return await _dbContext.SpecializationSkills
            .AsNoTracking()
            .Where(ss =>
                ss.SpecializationId == specializationId &&
                ss.Skill.IsActive)
            .ToListAsync();
    }

    public async Task<List<ContentSkill>> GetActiveContentLinksAsync(
        IReadOnlyCollection<Guid> skillIds)
    {
        return await _dbContext.ContentSkills
            .AsNoTracking()
            .Where(cs =>
                skillIds.Contains(cs.SkillId) &&
                cs.Content.IsActive)
            .ToListAsync();
    }

    public async Task<List<Quiz>> GetActiveQuizzesAsync(
        IReadOnlyCollection<Guid> skillIds)
    {
        return await _dbContext.Quizzes
            .AsNoTracking()
            .Where(q =>
                q.IsActive &&
                q.SkillId != null &&
                skillIds.Contains(q.SkillId.Value))
            .ToListAsync();
    }

    public async Task<List<QuizAttempt>> GetUserQuizAttemptsAsync(
        Guid userId,
        IReadOnlyCollection<Guid> quizIds)
    {
        return await _dbContext.QuizAttempts
            .AsNoTracking()
            .Where(a =>
                a.UserId == userId &&
                quizIds.Contains(a.QuizId))
            .ToListAsync();
    }
}
