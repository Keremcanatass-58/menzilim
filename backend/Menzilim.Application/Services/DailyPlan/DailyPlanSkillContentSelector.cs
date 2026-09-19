using Menzilim.Application.DTOs.Skills;
using Menzilim.Domain;
using DomainContent = Menzilim.Domain.Content;

namespace Menzilim.Application.Services.DailyPlan;

/// <summary>
/// Günlük plan için skill ilerlemesine duyarlı içerik seçimi yapar.
/// Deterministiktir, veritabanına erişmez, AI kullanmaz.
///
/// Her seçim adımında:
///   1) Devam eden (başlanmış, tamamlanmamış) içerik varsa önce o seçilir.
///   2) Yoksa başlanmamış içerikler, bağlı oldukları kullanıcının uzmanlık
///      skill'lerinin EN DÜŞÜK ilerlemesine göre gruplanır; en düşük grup
///      seçilir. Uzmanlık skill'ine bağlı olmayan içerikler en sona kalır.
///   3) Grup içindeki seçim mevcut DailyPlanContentSelector kurallarıyla
///      yapılır (uzmanlık adı eşleşmesi → yayın tarihi → Id).
/// Tamamlanmış içerikler hiç seçilmez; aynı içerik iki kez seçilmez.
/// </summary>
public static class DailyPlanSkillContentSelector
{
    public sealed record Selection(
        Guid ContentId,
        string Title,
        bool IsContinuation,
        string? FocusSkillName);

    // Uzmanlık skill'ine bağlı olmayan içeriğin önceliği (tüm yüzdelerden sonra).
    private const int UnlinkedPriority = int.MaxValue;

    /// <param name="professionContent">Kullanıcının mesleğine ait aktif içerikler (seçim kapsamı).</param>
    /// <param name="progress">Kullanıcının içerik ilerleme kayıtları.</param>
    /// <param name="contentSkills">İçerik ↔ skill ilişkileri.</param>
    /// <param name="skillProgress">Kullanıcının uzmanlık skill'lerinin SkillProgressEngine sonucu.</param>
    /// <param name="count">Seçilecek en fazla farklı içerik sayısı.</param>
    public static IReadOnlyList<Selection> Select(
        IReadOnlyList<DomainContent> professionContent,
        IReadOnlyList<UserContentProgress> progress,
        IReadOnlyList<ContentSkill> contentSkills,
        IReadOnlyList<SkillProgressResponse> skillProgress,
        string? specializationName,
        int count)
    {
        var result = new List<Selection>();

        if (count <= 0)
        {
            return result;
        }

        // Herhangi bir kaydı tamamlanmış içerik tamamlanmış sayılır. (Aynı
        // içerik için tamamlanmamış bir kopya kayıt olsa bile tekrar seçilmez.)
        var completedIds = progress
            .Where(p => p.IsCompleted || p.CompletedAt is not null)
            .Select(p => p.ContentId)
            .ToHashSet();

        var startedIds = progress
            .Select(p => p.ContentId)
            .ToHashSet();

        var skillsById = skillProgress
            .GroupBy(s => s.SkillId)
            .ToDictionary(g => g.Key, g => g.First());

        // İçerik → bağlı uzmanlık skill'leri (en düşük ilerleme önce).
        var skillsByContent = contentSkills
            .Where(cs => skillsById.ContainsKey(cs.SkillId))
            .GroupBy(cs => cs.ContentId)
            .ToDictionary(
                g => g.Key,
                g => g
                    .Select(cs => skillsById[cs.SkillId])
                    .DistinctBy(s => s.SkillId)
                    .OrderBy(s => s.ProgressPercent)
                    .ThenBy(s => s.SkillName, StringComparer.Ordinal)
                    .ThenBy(s => s.SkillId)
                    .ToList());

        var pool = professionContent
            .GroupBy(c => c.Id)
            .Select(g => g.First())
            .Where(c => !completedIds.Contains(c.Id))
            .ToList();

        while (result.Count < count && pool.Count > 0)
        {
            var next = PickNext(
                pool, progress, startedIds, skillsByContent, specializationName);

            if (next is null)
            {
                break;
            }

            result.Add(next);
            pool.RemoveAll(c => c.Id == next.ContentId);
        }

        return result;
    }

    private static Selection? PickNext(
        IReadOnlyList<DomainContent> pool,
        IReadOnlyList<UserContentProgress> progress,
        IReadOnlySet<Guid> startedIds,
        IReadOnlyDictionary<Guid, List<SkillProgressResponse>> skillsByContent,
        string? specializationName)
    {
        // 1) Devam eden içerik: mevcut seçicinin "kaldığın yerden devam" kuralı.
        var inProgress = pool
            .Where(c => startedIds.Contains(c.Id))
            .ToList();

        var candidates = inProgress.Count > 0
            ? inProgress
            : pool
                // 2) Başlanmamış içerikler: en düşük ilerlemeli skill grubu.
                .GroupBy(c => Priority(c.Id, skillsByContent))
                .OrderBy(g => g.Key)
                .First()
                .ToList();

        // 3) Grup içi seçim mevcut DailyPlanContentSelector ile.
        var selection = DailyPlanContentSelector.Select(
            candidates, progress, specializationName);

        if (selection.ContentId is not Guid contentId)
        {
            return null;
        }

        var focusSkill = skillsByContent.TryGetValue(contentId, out var skills)
            ? skills[0].SkillName
            : null;

        return new Selection(
            contentId,
            selection.Title ?? string.Empty,
            selection.IsContinuation,
            focusSkill);
    }

    private static int Priority(
        Guid contentId,
        IReadOnlyDictionary<Guid, List<SkillProgressResponse>> skillsByContent)
    {
        return skillsByContent.TryGetValue(contentId, out var skills)
            ? skills[0].ProgressPercent
            : UnlinkedPriority;
    }
}
