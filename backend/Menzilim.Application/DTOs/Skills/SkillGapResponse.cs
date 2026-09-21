namespace Menzilim.Application.DTOs.Skills;

/// <summary>
/// Kullanıcının uzmanlık yolundaki beceri açığı. Seviyeler MENZİLİM öğrenme
/// yolundaki hedeflerdir; istemci ham değerleri kendi dilinde gösterir.
/// </summary>
public class SkillGapResponse
{
    public string SpecializationName { get; set; } = string.Empty;

    public int TotalCount { get; set; }

    /// <summary>Hedef seviyeye ulaşmış beceri sayısı.</summary>
    public int ReachedCount { get; set; }

    /// <summary>Üzerinde ilerleme olan ama hedefe ulaşmamış beceri sayısı.</summary>
    public int DevelopingCount { get; set; }

    /// <summary>Hiç ilerleme olmayan beceri sayısı.</summary>
    public int NotStartedCount { get; set; }

    /// <summary>Hedefe ulaşmamış becerilerin toplamı (Developing + NotStarted).</summary>
    public int RemainingCount { get; set; }

    /// <summary>Önce hedefe en yakın eksik beceriler.</summary>
    public List<SkillGapItemResponse> Items { get; set; } = new();
}

public class SkillGapItemResponse
{
    public Guid SkillId { get; set; }

    public string SkillName { get; set; } = string.Empty;

    public string Category { get; set; } = string.Empty;

    /// <summary>None | Beginner | Intermediate | Advanced</summary>
    public string CurrentLevel { get; set; } = string.Empty;

    /// <summary>Beginner | Intermediate | Advanced</summary>
    public string TargetLevel { get; set; } = string.Empty;

    /// <summary>İçerik ve quiz aktivitesinden gelen ilerleme (0-100).</summary>
    public int ProgressPercent { get; set; }

    /// <summary>Hedef seviyenin gerektirdiği ilerleme eşiği (0-100).</summary>
    public int TargetProgressPercent { get; set; }

    /// <summary>Reached | Developing | NeedsWork | NotStarted</summary>
    public string Status { get; set; } = string.Empty;
}
