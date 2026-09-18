namespace Menzilim.Application.DTOs.AICoach;

public class AICoachAnswerResponse
{
    /// <summary>
    /// AI koçunun ürettiği yanıt metni.
    /// </summary>
    public string Answer { get; set; } = string.Empty;

    /// <summary>
    /// Yanıtı üreten sağlayıcının adı (ör. "mock").
    /// </summary>
    public string Provider { get; set; } = string.Empty;

    /// <summary>
    /// Yanıtın üretildiği an (UTC).
    /// </summary>
    public DateTime CreatedAt { get; set; }
}
