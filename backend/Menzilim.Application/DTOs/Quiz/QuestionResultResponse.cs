namespace Menzilim.Application.DTOs.Quiz;

/// <summary>
/// Quiz gönderimi sonrası soru bazlı geri bildirim: kullanıcı neyi neden
/// yanlış yaptığını görebilsin.
/// </summary>
public class QuestionResultResponse
{
    public Guid QuestionId { get; set; }

    public string Text { get; set; } = string.Empty;

    /// <summary>Kullanıcının işaretlediği şık (boş bırakıldıysa null).</summary>
    public string? SelectedOption { get; set; }

    public string CorrectOption { get; set; } = string.Empty;

    public string? CorrectOptionText { get; set; }

    public bool IsCorrect { get; set; }

    public string? Explanation { get; set; }
}
