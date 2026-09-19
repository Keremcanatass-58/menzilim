using DomainQuiz = Menzilim.Domain.Quiz;
using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface IQuizRepository
{
    Task<List<DomainQuiz>> GetAllActiveAsync();
    Task<DomainQuiz?> GetByIdWithQuestionsAsync(Guid id);
    Task<DomainQuiz?> GetFirstActiveWithQuestionsAsync();
    Task AddAttemptAsync(QuizAttempt attempt);
    Task<int> GetAttemptCountByUserAsync(Guid userId);
    Task<List<QuizAttempt>> GetByUserAsync(Guid userId);
    Task SaveChangesAsync();
}