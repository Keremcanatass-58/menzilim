using Menzilim.Application.DTOs.Content;
using Menzilim.Domain;
using DomainContent = Menzilim.Domain.Content;

namespace Menzilim.Application.Services.Content;

/// <summary>
/// Kullanıcı profiline ve içerik ilerlemesine göre deterministik içerik önerisi
/// üretir. AI kullanmaz. DailyPlanContentSelector'dan bağımsızdır.
/// </summary>
public static class ContentRecommendationEngine
{
    public const int DefaultCount = 5;

    /// <param name="professionContent">Kullanıcının mesleğine ait aktif içerikler.</param>
    /// <param name="allActiveContent">Fallback için tüm aktif içerikler.</param>
    /// <param name="progress">Kullanıcının içerik ilerlemesi.</param>
    public static List<ContentRecommendationResponse> Recommend(
        IReadOnlyList<DomainContent> professionContent,
        IReadOnlyList<DomainContent> allActiveContent,
        IReadOnlyList<UserContentProgress> progress,
        string? professionName,
        string? specializationName,
        string? experienceLevel,
        string? careerGoal,
        int count = DefaultCount)
    {
        var take = count <= 0 ? DefaultCount : count;

        var completedIds = progress
            .Where(p => p.IsCompleted)
            .Select(p => p.ContentId)
            .ToHashSet();

        var startedIds = progress
            .Select(p => p.ContentId)
            .ToHashSet();

        var inProgressIds = progress
            .Where(p => !p.IsCompleted)
            .Select(p => p.ContentId)
            .ToHashSet();

        var professionIds = professionContent
            .Select(c => c.Id)
            .ToHashSet();

        // Aday havuzu: önce meslek içerikleri, sonra diğer aktif içerikler.
        // Id'ye göre tekilleştir; tamamlananları dışla.
        var candidates = professionContent
            .Concat(allActiveContent)
            .GroupBy(c => c.Id)
            .Select(g => g.First())
            .Where(c => !completedIds.Contains(c.Id))
            .ToList();

        var ordered = candidates
            .OrderBy(c => Tier(c, specializationName, inProgressIds, professionIds))
            .ThenByDescending(c => LevelMatch(c, experienceLevel))
            .ThenByDescending(c => c.PublishedAt)
            .ThenBy(c => c.Id)
            .Take(take)
            .ToList();

        return ordered
            .Select(c => new ContentRecommendationResponse
            {
                ContentId = c.Id,
                Title = c.Title,
                Description = c.Description,
                Url = c.Url,
                IsStarted = startedIds.Contains(c.Id),
                IsCompleted = completedIds.Contains(c.Id),
                RecommendationReason = Reason(
                    Tier(c, specializationName, inProgressIds, professionIds),
                    professionName,
                    specializationName,
                    careerGoal),
            })
            .ToList();
    }

    private static int Tier(
        DomainContent content,
        string? specialization,
        IReadOnlyCollection<Guid> inProgressIds,
        IReadOnlyCollection<Guid> professionIds)
    {
        var specMatch = SpecializationMatch(content, specialization);
        var inProgress = inProgressIds.Contains(content.Id);

        if (specMatch && inProgress) return 0;
        if (specMatch) return 1;
        if (inProgress) return 2;
        if (professionIds.Contains(content.Id)) return 3;

        return 4;
    }

    private static int LevelMatch(
        DomainContent content,
        string? experienceLevel)
    {
        if (string.IsNullOrWhiteSpace(experienceLevel))
        {
            return 0;
        }

        return string.Equals(
            content.Level.Trim(),
            experienceLevel.Trim(),
            StringComparison.OrdinalIgnoreCase)
            ? 1
            : 0;
    }

    private static bool SpecializationMatch(
        DomainContent content,
        string? specialization)
    {
        if (string.IsNullOrWhiteSpace(specialization))
        {
            return false;
        }

        var term = specialization.Trim();

        var inTitle = content.Title
            .Contains(term, StringComparison.OrdinalIgnoreCase);

        var inDescription = content.Description is not null &&
            content.Description.Contains(term, StringComparison.OrdinalIgnoreCase);

        return inTitle || inDescription;
    }

    private static string Reason(
        int tier,
        string? professionName,
        string? specializationName,
        string? careerGoal)
    {
        switch (tier)
        {
            case 0:
            case 2:
                return "Bu içeriğe başlamışsın, kaldığın yerden devam edebilirsin.";

            case 1:
                return string.IsNullOrWhiteSpace(specializationName)
                    ? "Uzmanlık alanınla ilgili olduğu için öneriliyor."
                    : $"Uzmanlığın {specializationName.Trim()} olduğu için öneriliyor.";

            case 3:
                return string.IsNullOrWhiteSpace(professionName)
                    ? "Mesleğinle ilgili olduğu için öneriliyor."
                    : $"Mesleğin {professionName.Trim()} ile ilgili olduğu için öneriliyor.";

            default:
                return string.IsNullOrWhiteSpace(careerGoal)
                    ? "Gelişimine katkı sağlayabilecek bir içerik."
                    : $"Kariyer hedefin ({careerGoal.Trim()}) doğrultusunda önerilen bir içerik.";
        }
    }
}