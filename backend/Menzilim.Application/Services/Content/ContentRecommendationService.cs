using Menzilim.Application.DTOs.Content;
using Menzilim.Application.Interfaces.Content;
using Menzilim.Application.Interfaces.Repositories;

namespace Menzilim.Application.Services.Content;

public class ContentRecommendationService : IContentRecommendationService
{
    private readonly IUserRepository _userRepository;
    private readonly IContentRepository _contentRepository;
    private readonly IUserContentProgressRepository _progressRepository;

    public ContentRecommendationService(
        IUserRepository userRepository,
        IContentRepository contentRepository,
        IUserContentProgressRepository progressRepository)
    {
        _userRepository = userRepository;
        _contentRepository = contentRepository;
        _progressRepository = progressRepository;
    }

    public async Task<List<ContentRecommendationResponse>> GetForUserAsync(
        Guid userId)
    {
        var user =
            await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user is null)
            throw new KeyNotFoundException("Kullanıcı bulunamadı.");

        var profile = user.Profile;

        if (profile is null)
            throw new KeyNotFoundException("Kullanıcı profili bulunamadı.");

        var professionContent =
            await _contentRepository.GetByProfessionAsync(profile.ProfessionId);
        var progress =
            await _progressRepository.GetByUserAsync(userId);

        // Tüm aktif içerikler yalnızca meslek dışında devam eden içerik varsa
        // gerekir; aksi halde tabloyu boşuna okumayalım.
        var professionIds = professionContent
            .Select(c => c.Id)
            .ToHashSet();

        var hasInProgressOutsideProfession = progress
            .Any(p => !p.IsCompleted && !professionIds.Contains(p.ContentId));

        var allActiveContent = hasInProgressOutsideProfession
            ? await _contentRepository.GetActiveAsync()
            : new List<Menzilim.Domain.Content>();

        return ContentRecommendationEngine.Recommend(
            professionContent,
            allActiveContent,
            progress,
            profile.Profession?.Name,
            profile.Specialization?.Name,
            profile.ExperienceLevel,
            profile.CareerGoal);
    }
}
