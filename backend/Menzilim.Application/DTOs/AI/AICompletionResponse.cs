namespace Menzilim.Application.DTOs.AI;

public class AICompletionResponse
{
    /// <summary>
    /// AI sağlayıcısının ürettiği yanıt metni.
    /// </summary>
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// Yanıtı üreten sağlayıcının adı (ör. "mock").
    /// </summary>
    public string Provider { get; set; } = string.Empty;

    /// <summary>
    /// Yanıtın üretildiği an (UTC).
    /// </summary>
    public DateTime CreatedAt { get; set; }
}
