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
        var results = new List<QuestionResultResponse>();

        foreach (var question in questions)
        {
            answersMap.TryGetValue(question.Id, out var selectedOption);

            var answered = !string.IsNullOrWhiteSpace(selectedOption);

            var isCorrect = answered && string.Equals(
                selectedOption!.Trim(),
                question.CorrectOption.Trim(),
                StringComparison.OrdinalIgnoreCase);

            if (isCorrect)
            {
                correctAnswers++;
            }

            results.Add(new QuestionResultResponse
            {
                QuestionId = question.Id,
                Text = question.Text,
                SelectedOption = answered ? selectedOption!.Trim() : null,
                CorrectOption = question.CorrectOption.Trim(),
                CorrectOptionText = OptionText(question, question.CorrectOption),
                IsCorrect = isCorrect,
                Explanation = question.Explanation
            });
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
            SuccessRate = successRate,
            Results = results
        };
    }

    /// <summary>Şık harfinin metnini döner ("A" → OptionA).</summary>
    private static string? OptionText(Question question, string option)
    {
        return option.Trim().ToUpperInvariant() switch
        {
            "A" => question.OptionA,
            "B" => question.OptionB,
            "C" => question.OptionC,
            "D" => question.OptionD,
            _ => null
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
