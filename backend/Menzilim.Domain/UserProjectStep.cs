namespace Menzilim.Domain;

/// <summary>
/// Projenin tek bir adımı. Sıra LearningItem.Order ile aynıdır; yalnızca
/// Available adım tamamlanabilir.
/// </summary>
public class UserProjectStep
{
    public Guid Id { get; set; }

    public Guid UserProjectId { get; set; }

    public Guid LearningItemId { get; set; }

    public int Order { get; set; }

    /// <summary>Locked | Available | Completed</summary>
    public string Status { get; set; } = UserProjectStepStatus.Locked;

    public DateTime? CompletedAt { get; set; }

    /// <summary>Adımın çıktısı (repo linki vb.). Şimdilik opsiyonel.</summary>
    public string? EvidenceUrl { get; set; }

    public string? Note { get; set; }

    public UserProject UserProject { get; set; } = null!;

    public LearningItem LearningItem { get; set; } = null!;
}

public static class UserProjectStepStatus
{
    public const string Locked = "Locked";
    public const string Available = "Available";
    public const string Completed = "Completed";
}
