namespace Menzilim.Application.DTOs.Quiz;

public class QuizDetailResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public List<QuestionResponse> Questions { get; set; } = new();
}
