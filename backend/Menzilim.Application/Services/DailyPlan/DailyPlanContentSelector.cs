using Menzilim.Domain;
using DomainContent = Menzilim.Domain.Content;

namespace Menzilim.Application.Services.DailyPlan;

/// <summary>
/// Learn görevi için kullanıcının mesleğine/uzmanlığına ve ilerlemesine göre
/// deterministik içerik seçimi yapar. AI kullanmaz.
/// </summary>
public static class DailyPlanContentSelector
{
    public sealed record Selection(
        Guid? ContentId,
        string? Title,
        bool IsContinuation);

    public static readonly Selection None = new(null, null, false);

    /// <param name="professionContent">
    /// Kullanıcının mesleğine ait aktif içerikler.
    /// </param>
    /// <param name="progress">Kullanıcının içerik ilerlemesi.</param>
    /// <param name="specializationName">Uzmanlık adı (yumuşak eşleşme için).</param>
    public static Selection Select(
        IReadOnlyList<DomainContent> professionContent,
        IReadOnlyList<UserContentProgress> progress,
        string? specializationName)
    {
        if (professionContent.Count == 0)
        {
            return None;
        }

        var completedIds = progress
            .Where(p => p.IsCompleted)
            .Select(p => p.ContentId)
            .ToHashSet();

        var startedAtByContentId = progress
            .Where(p => !p.IsCompleted)
            .GroupBy(p => p.ContentId)
            .ToDictionary(g => g.Key, g => g.Max(p => p.StartedAt));

        // 1) Devam eden içerik varsa "kaldığın yerden devam et".
        var continueCandidate = professionContent
            .Where(c => startedAtByContentId.ContainsKey(c.Id))
            .OrderByDescending(c => startedAtByContentId[c.Id])
            .ThenBy(c => c.Id)
            .FirstOrDefault();

        if (continueCandidate is not null)
        {
            return new Selection(continueCandidate.Id, continueCandidate.Title, true);
        }

        // 2) Tamamlanmamış ve başlanmamış içerikler; uzmanlığa uyanı önceliklendir.
        var fresh = professionContent
            .Where(c =>
                !completedIds.Contains(c.Id) &&
                !startedAtByContentId.ContainsKey(c.Id))
            .OrderByDescending(c => SpecializationMatch(c, specializationName))
            .ThenByDescending(c => c.PublishedAt)
            .ThenBy(c => c.Id)
            .ToList();

        if (fresh.Count > 0)
        {
            var best = fresh[0];
            return new Selection(best.Id, best.Title, false);
        }

        // 3) Uygun içerik yok (hepsi tamamlanmış vb.) → güvenli fallback.
        return None;
    }

    private static int SpecializationMatch(DomainContent content, string? specialization)
    {
        if (string.IsNullOrWhiteSpace(specialization))
        {
            return 0;
        }

        var term = specialization.Trim();

        var inTitle = content.Title
            .Contains(term, StringComparison.OrdinalIgnoreCase);

        var inDescription = content.Description is not null &&
            content.Description.Contains(term, StringComparison.OrdinalIgnoreCase);

        return inTitle || inDescription ? 1 : 0;
    }
}
