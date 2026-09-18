namespace Menzilim.Application.DTOs.AICoach;

public class AICoachAskRequest
{
    /// <summary>
    /// Kullanıcının AI koçuna sorduğu soru / mesaj.
    /// </summary>
    public string Prompt { get; set; } = string.Empty;
}
