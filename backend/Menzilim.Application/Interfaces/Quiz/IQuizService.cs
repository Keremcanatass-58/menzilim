using Menzilim.Application.DTOs.Quiz;

namespace Menzilim.Application.Interfaces.Quiz;

public interface IQuizService
{
    Task<List<QuizSummaryResponse>> GetAllActiveAsync();
    Task<QuizDetailResponse?> GetByIdAsync(Guid quizId);
    Task<QuizDetailResponse?> GetActiveQuizAsync();
    Task<QuizSubmitResultResponse> SubmitAsync(Guid userId, Guid quizId, QuizSubmitRequest request);
}
