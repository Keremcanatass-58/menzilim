namespace Menzilim.Domain;

public class Question
{
    public Guid Id { get; set; }
    public Guid QuizId { get; set; }
    public string Text { get; set; } = string.Empty;
    public string OptionA { get; set; } = string.Empty;
    public string OptionB { get; set; } = string.Empty;
    public string OptionC { get; set; } = string.Empty;
    public string OptionD { get; set; } = string.Empty;
    public string CorrectOption { get; set; } = string.Empty;

    /// <summary>Cevaptan sonra gösterilen kısa açıklama (opsiyonel).</summary>
    public string? Explanation { get; set; }

    public Quiz Quiz { get; set; } = null!;
}
