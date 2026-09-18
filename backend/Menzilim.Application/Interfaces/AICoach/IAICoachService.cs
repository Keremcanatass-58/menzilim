using Menzilim.Application.DTOs.AICoach;

namespace Menzilim.Application.Interfaces.AICoach;

public interface IAICoachService
{
    /// <summary>
    /// Giriş yapan kullanıcının profil bilgilerini bağlam olarak kullanarak
    /// AI koçundan bir yanıt üretir.
    /// </summary>
    Task<AICoachAnswerResponse> AskAsync(
        Guid userId,
        AICoachAskRequest request,
        CancellationToken cancellationToken = default);
}
