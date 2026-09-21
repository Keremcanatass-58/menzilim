using Menzilim.Application.DTOs.Skills;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Skills;

/// <summary>
/// Beceri açığını mevcut ilerlemeden ve uzmanlığın hedef seviyesinden
/// deterministik olarak hesaplar. Veritabanına erişmez, ilerleme formülünü
/// değiştirmez; yalnızca <see cref="SkillProgressEngine"/> çıktısını yorumlar.
///
/// Durumlar:
///   Reached     → mevcut seviye hedefe ulaşmış
///   Developing  → hedefin yarısı ve üzerinde ilerleme var
///   NeedsWork   → ilerleme var ama hedefin yarısının altında
///   NotStarted  → hiç ilerleme yok
/// </summary>
public static class SkillGapEngine
{
    public const string Reached = "Reached";
    public const string Developing = "Developing";
    public const string NeedsWork = "NeedsWork";
    public const string NotStarted = "NotStarted";

    public static SkillGapResponse Calculate(
        string specializationName,
        IReadOnlyList<SkillProgressResponse> progress,
        IReadOnlyDictionary<Guid, string> targetLevelsBySkillId)
    {
        var items = progress
            .Select(skill => Build(skill, targetLevelsBySkillId))
            .OrderBy(item => StatusRank(item.Status))
            .ThenByDescending(item => item.ProgressPercent)
            .ThenBy(item => item.SkillName, StringComparer.Ordinal)
            .ToList();

        var reached = items.Count(i => i.Status == Reached);
        var developing = items.Count(i => i.Status == Developing);
        var needsWork = items.Count(i => i.Status == NeedsWork);
        var notStarted = items.Count(i => i.Status == NotStarted);

        return new SkillGapResponse
        {
            SpecializationName = specializationName,
            TotalCount = items.Count,
            ReachedCount = reached,
            // "Geliştiriliyor": üzerinde ilerleme olan ama hedefe ulaşmamışlar.
            DevelopingCount = developing + needsWork,
            NotStartedCount = notStarted,
            RemainingCount = items.Count - reached,
            Items = items,
        };
    }

    private static SkillGapItemResponse Build(
        SkillProgressResponse skill,
        IReadOnlyDictionary<Guid, string> targetLevelsBySkillId)
    {
        var target = targetLevelsBySkillId.TryGetValue(skill.SkillId, out var level)
            && !string.IsNullOrWhiteSpace(level)
                ? level
                : SkillLevels.Intermediate;

        var currentLevel = SkillLevels.FromProgress(skill.ProgressPercent);
        var targetProgress = SkillLevels.ProgressFor(target);

        return new SkillGapItemResponse
        {
            SkillId = skill.SkillId,
            SkillName = skill.SkillName,
            Category = skill.Category,
            CurrentLevel = currentLevel,
            TargetLevel = target,
            ProgressPercent = skill.ProgressPercent,
            TargetProgressPercent = targetProgress,
            Status = Status(skill.ProgressPercent, currentLevel, target, targetProgress),
        };
    }

    private static string Status(
        int progressPercent,
        string currentLevel,
        string targetLevel,
        int targetProgress)
    {
        if (SkillLevels.Rank(currentLevel) >= SkillLevels.Rank(targetLevel))
        {
            return Reached;
        }

        if (progressPercent <= 0)
        {
            return NotStarted;
        }

        return progressPercent * 2 >= targetProgress ? Developing : NeedsWork;
    }

    // Önce hedefe en yakın eksikler: kullanıcının sıradaki kazanımı.
    private static int StatusRank(string status) => status switch
    {
        Developing => 0,
        NeedsWork => 1,
        NotStarted => 2,
        _ => 3,
    };
}
