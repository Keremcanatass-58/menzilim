namespace Menzilim.Domain;

/// <summary>
/// Kullanıcının gelişen projesi (Living Project). Şablon LearningPath'ten
/// üretilir; adımlar LearningItem sırasını izler.
/// </summary>
public class UserProject
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid LearningPathId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    /// <summary>NotStarted | InProgress | Completed</summary>
    public string Status { get; set; } = UserProjectStatus.NotStarted;

    public DateTime? StartedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;

    public LearningPath LearningPath { get; set; } = null!;

    public ICollection<UserProjectStep> Steps { get; set; } =
        new List<UserProjectStep>();
}

public static class UserProjectStatus
{
    public const string NotStarted = "NotStarted";
    public const string InProgress = "InProgress";
    public const string Completed = "Completed";
}
