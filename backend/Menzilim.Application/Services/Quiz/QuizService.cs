using Menzilim.Application.DTOs.Quiz;
using Menzilim.Application.Interfaces.Quiz;
using Menzilim.Application.Interfaces.Repositories;
using DomainQuiz = Menzilim.Domain.Quiz;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Quiz;

public class QuizService : IQuizService
{
    private readonly IQuizRepository _quizRepository;

    public QuizService(IQuizRepository quizRepository)
    {
        _quizRepository = quizRepository;
    }

    public async Task<List<QuizSummaryResponse>> GetAllActiveAsync()
    {
        var quizzes = await _quizRepository.GetAllActiveAsync();

        return quizzes.Select(q => new QuizSummaryResponse
        {
            Id = q.Id,
            Title = q.Title,
            Description = q.Description,
            QuestionCount = q.Questions.Count
        }).ToList();
    }

    public async Task<QuizDetailResponse?> GetByIdAsync(Guid quizId)
    {
        var quiz = await _quizRepository.GetByIdWithQuestionsAsync(quizId);

        if (quiz is null)
            return null;

        return MapToDetailResponse(quiz);
    }

    public async Task<QuizDetailResponse?> GetActiveQuizAsync()
    {
        var quiz = await _quizRepository.GetFirstActiveWithQuestionsAsync();

        if (quiz is null)
            return null;

        return MapToDetailResponse(quiz);
    }

    public async Task<QuizSubmitResultResponse> SubmitAsync(Guid userId, Guid quizId, QuizSubmitRequest request)
    {
        var quiz = await _quizRepository.GetByIdWithQuestionsAsync(quizId);

        if (quiz is null)
        {
            throw new KeyNotFoundException("Quiz bulunamadı.");
        }

        var questions = quiz.Questions.ToList();
        var totalQuestions = questions.Count;

        if (totalQuestions == 0)
        {
            throw new InvalidOperationException("Quiz'e ait soru bulunamadı.");
        }

        var answersMap = request.Answers
            .Where(a => a != null)
            .ToDictionary(a => a.QuestionId, a => a.SelectedOption);

        int correctAnswers = 0;

        foreach (var question in questions)
        {
            if (answersMap.TryGetValue(question.Id, out var selectedOption) &&
                !string.IsNullOrWhiteSpace(selectedOption))
            {
                if (string.Equals(selectedOption.Trim(), question.CorrectOption.Trim(), StringComparison.OrdinalIgnoreCase))
                {
                    correctAnswers++;
                }
            }
        }

        int wrongAnswers = totalQuestions - correctAnswers;
        int score = (int)Math.Round((double)correctAnswers / totalQuestions * 100);
        double successRate = Math.Round((double)correctAnswers / totalQuestions * 100, 1);

        var attempt = new QuizAttempt
        {
            Id = Guid.NewGuid(),
            QuizId = quizId,
            UserId = userId,
            Score = score,
            CorrectAnswers = correctAnswers,
            TotalQuestions = totalQuestions,
            CompletedAt = DateTime.UtcNow
        };

        await _quizRepository.AddAttemptAsync(attempt);
        await _quizRepository.SaveChangesAsync();

        return new QuizSubmitResultResponse
        {
            AttemptId = attempt.Id,
            QuizId = quizId,
            Score = score,
            CorrectAnswers = correctAnswers,
            WrongAnswers = wrongAnswers,
            TotalQuestions = totalQuestions,
            SuccessRate = successRate
        };
    }

    private static QuizDetailResponse MapToDetailResponse(DomainQuiz quiz)
    {
        return new QuizDetailResponse
        {
            Id = quiz.Id,
            Title = quiz.Title,
            Description = quiz.Description,
            Questions = quiz.Questions.Select(q => new QuestionResponse
            {
                Id = q.Id,
                Text = q.Text,
                OptionA = q.OptionA,
                OptionB = q.OptionB,
                OptionC = q.OptionC,
                OptionD = q.OptionD
            }).ToList()
        };
    }
}
