namespace Menzilim.Application.DTOs.Quiz;

public class QuizSubmitRequest
{
    public List<QuestionAnswerRequest> Answers { get; set; } = new();
}
