using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Interfaces.Skills;

namespace Menzilim.Application.Services.Skills;

/// <summary>
/// Beceri açığı: mevcut ilerleme (mevcut /api/skills/me hesabı) ile uzmanlığın
/// hedef seviyelerini karşılaştırır. İlerleme formülü değişmez.
/// </summary>
public class SkillGapService : ISkillGapService
{
    private readonly ISkillService _skillService;
    private readonly ISkillRepository _skillRepository;
    private readonly IUserRepository _userRepository;

    public SkillGapService(
        ISkillService skillService,
        ISkillRepository skillRepository,
        IUserRepository userRepository)
    {
        _skillService = skillService;
        _skillRepository = skillRepository;
        _userRepository = userRepository;
    }

    public async Task<SkillGapResponse> GetForUserAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);
        var profile = user?.Profile;

        if (profile is null)
        {
            throw new KeyNotFoundException("Kullanıcı profili bulunamadı.");
        }

        var progress = await _skillService.GetMyProgressAsync(userId);

        var targets = (await _skillRepository
                .GetSpecializationSkillsAsync(profile.SpecializationId))
            .GroupBy(ss => ss.SkillId)
            .ToDictionary(g => g.Key, g => g.First().TargetLevel);

        return SkillGapEngine.Calculate(
            profile.Specialization?.Name ?? string.Empty,
            progress,
            targets);
    }
}
