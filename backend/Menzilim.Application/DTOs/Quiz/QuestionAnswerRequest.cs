namespace Menzilim.Application.DTOs.Quiz;

public class QuestionAnswerRequest
{
    public Guid QuestionId { get; set; }
    public string SelectedOption { get; set; } = string.Empty;
}
