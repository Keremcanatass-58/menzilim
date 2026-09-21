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
    /// <param name="allActiveContent">
    /// Tüm aktif içerikler. Yalnızca kullanıcının meslek dışında başladığı
    /// içerikleri bulmak için kullanılır; başka meslek içerikleri önerilmez.
    /// </param>
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
        // En fazla DefaultCount (5) öneri döner.
        var take = count <= 0 || count > DefaultCount ? DefaultCount : count;

        var completedIds = progress
            .Where(p => p.IsCompleted)
            .Select(p => p.ContentId)
            .ToHashSet();

        var startedIds = progress
            .Select(p => p.ContentId)
            .ToHashSet();

        // Bir içerik tamamlanmış kaydı varsa devam eden sayılmaz.
        var inProgressIds = progress
            .Where(p => !p.IsCompleted && !completedIds.Contains(p.ContentId))
            .Select(p => p.ContentId)
            .ToHashSet();

        // Aday havuzu: meslek içerikleri + kullanıcının başladığı (meslek dışı
        // olsa bile) içerikler. Id'ye göre tekilleştir; tamamlananları dışla.
        var candidates = professionContent
            .Concat(allActiveContent.Where(c => inProgressIds.Contains(c.Id)))
            .GroupBy(c => c.Id)
            .Select(g => g.First())
            .Where(c => !completedIds.Contains(c.Id))
            .ToList();

        var ordered = candidates
            .Select(c => new
            {
                Content = c,
                Tier = Tier(c, specializationName, inProgressIds),
                LevelMatch = LevelMatch(c, experienceLevel),
            })
            .OrderBy(x => x.Tier)
            .ThenByDescending(x => x.LevelMatch)
            .ThenByDescending(x => x.Content.PublishedAt)
            .ThenBy(x => x.Content.Id)
            .Take(take)
            .ToList();

        return ordered
            .Select(x => new ContentRecommendationResponse
            {
                ContentId = x.Content.Id,
                Title = x.Content.Title,
                Description = x.Content.Description,
                Url = x.Content.Url,
                IsStarted = startedIds.Contains(x.Content.Id),
                IsCompleted = completedIds.Contains(x.Content.Id),
                RecommendationReason = Reason(
                    x.Tier,
                    x.LevelMatch == 1,
                    professionName,
                    specializationName,
                    experienceLevel,
                    careerGoal),
            })
            .ToList();
    }

    // 0: devam eden + uzmanlık, 1: devam eden, 2: uzmanlık, 3: meslek (fallback).
    private static int Tier(
        DomainContent content,
        string? specialization,
        IReadOnlyCollection<Guid> inProgressIds)
    {
        var specMatch = SpecializationMatch(content, specialization);
        var inProgress = inProgressIds.Contains(content.Id);

        if (inProgress && specMatch) return 0;
        if (inProgress) return 1;
        if (specMatch) return 2;

        return 3;
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

    /// <summary>
    /// Deneyim seviyesinin görünen karşılığı; ham İngilizce değer kullanıcıya
    /// gösterilmez.
    /// </summary>
    private static string LevelLabel(string level) =>
        level.Trim().ToLowerInvariant() switch
        {
            "beginner" => "Başlangıç",
            "intermediate" => "Orta",
            "advanced" => "İleri",
            _ => level.Trim(),
        };

    private static string Reason(
        int tier,
        bool levelMatch,
        string? professionName,
        string? specializationName,
        string? experienceLevel,
        string? careerGoal)
    {
        var levelSuffix = levelMatch && !string.IsNullOrWhiteSpace(experienceLevel)
            ? $" {LevelLabel(experienceLevel!)} seviyene uygun."
            : string.Empty;

        switch (tier)
        {
            case 0:
                return $"Uzmanlığın {specializationName!.Trim()} ile ilgili bu içeriğe başlamışsın, kaldığın yerden devam edebilirsin.";

            case 1:
                return "Bu içeriğe başlamışsın, kaldığın yerden devam edebilirsin.";

            case 2:
                return $"Uzmanlığın {specializationName!.Trim()} olduğu için öneriliyor.{levelSuffix}";

            default:
                var professionPart = string.IsNullOrWhiteSpace(professionName)
                    ? "Mesleğinle ilgili olduğu için öneriliyor."
                    : $"Mesleğin {professionName.Trim()} ile ilgili olduğu için öneriliyor.";

                var goalSuffix = string.IsNullOrWhiteSpace(careerGoal)
                    ? string.Empty
                    : $" Kariyer hedefin ({careerGoal.Trim()}) doğrultusunda faydalı olabilir.";

                return $"{professionPart}{levelSuffix}{goalSuffix}";
        }
    }
}