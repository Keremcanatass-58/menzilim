using Menzilim.Application.DTOs.Skills;

namespace Menzilim.Application.Interfaces.Skills;

public interface ISkillGapService
{
    /// <summary>
    /// Kullanıcının uzmanlığındaki beceriler için mevcut/hedef seviye ve
    /// durum. Onboarding yapılmamışsa KeyNotFoundException.
    /// </summary>
    Task<SkillGapResponse> GetForUserAsync(Guid userId);
}
