using Microsoft.EntityFrameworkCore;
using Menzilim.Application.Interfaces.Repositories;
using DomainQuiz = Menzilim.Domain.Quiz;
using Menzilim.Domain;
using Menzilim.Infrastructure.Data;

namespace Menzilim.Infrastructure.Repositories;

public class QuizRepository : IQuizRepository
{
    private readonly MenzilimDbContext _dbContext;

    public QuizRepository(MenzilimDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<DomainQuiz>> GetAllActiveAsync()
    {
        return await _dbContext.Quizzes
            .Where(q => q.IsActive)
            .Include(q => q.Questions)
            .OrderBy(q => q.CreatedAt)
            .ToListAsync();
    }

    public async Task<DomainQuiz?> GetByIdWithQuestionsAsync(Guid id)
    {
        return await _dbContext.Quizzes
            .Include(q => q.Questions)
            .FirstOrDefaultAsync(q => q.Id == id && q.IsActive);
    }

    public async Task<DomainQuiz?> GetFirstActiveWithQuestionsAsync()
    {
        return await _dbContext.Quizzes
            .Include(q => q.Questions)
            .FirstOrDefaultAsync(q => q.IsActive);
    }

    public async Task AddAttemptAsync(QuizAttempt attempt)
    {
        await _dbContext.QuizAttempts.AddAsync(attempt);
    }

    public async Task<int> GetAttemptCountByUserAsync(Guid userId)
    {
        return await _dbContext.QuizAttempts
            .CountAsync(a => a.UserId == userId);
    }

    public async Task SaveChangesAsync()
    {
        await _dbContext.SaveChangesAsync();
    }
}
