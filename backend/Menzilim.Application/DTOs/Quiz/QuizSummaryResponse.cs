namespace Menzilim.Application.DTOs.Quiz;

public class QuizSummaryResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int QuestionCount { get; set; }
}
