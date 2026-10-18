using Menzilim.Application.DTOs.Progress;

namespace Menzilim.Application.Interfaces.Progress;

public interface IStreakService
{
    /// <summary>
    /// Kullanıcının süreklilik özeti. Gerçek aktivitelerden (içerik, quiz,
    /// proje adımı) hesaplanır ve UserProgress'e yazılır.
    /// </summary>
    Task<StreakResponse> GetForUserAsync(Guid userId);

    /// <summary>
    /// İstemcinin bildirdiği saat dilimini profile yazar. Geçersiz değer
    /// yok sayılır ve mevcut/varsayılan değer korunur.
    /// </summary>
    Task<int> UpdateTimeZoneAsync(Guid userId, int offsetMinutes);
}
