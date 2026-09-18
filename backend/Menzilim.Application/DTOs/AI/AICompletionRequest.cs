namespace Menzilim.Application.DTOs.AI;

public class AICompletionRequest
{
    /// <summary>
    /// Kullanıcının AI koçuna gönderdiği mesaj / soru.
    /// </summary>
    public string Prompt { get; set; } = string.Empty;

    /// <summary>
    /// AI koçunun davranışını yönlendiren opsiyonel sistem talimatı / bağlam.
    /// </summary>
    public string? SystemPrompt { get; set; }
}
