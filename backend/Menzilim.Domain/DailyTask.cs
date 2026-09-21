namespace Menzilim.Domain;

public class DailyTask
{
    public Guid Id { get; set; }
    public Guid DailyPlanId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string TaskType { get; set; } = string.Empty;
    public int EstimatedMinutes { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }

    // Learn görevi için ilişkilendirilen içerik (opsiyonel).
    public Guid? ContentId { get; set; }

    /// <summary>
    /// Görev bir Living Project adımından üretildiyse o adım (opsiyonel).
    /// Adım tamamlanınca bu görev de tamamlanmış sayılır; tersi olmaz.
    /// </summary>
    public Guid? UserProjectStepId { get; set; }

    public UserProjectStep? UserProjectStep { get; set; }

    public DailyPlan DailyPlan { get; set; } = null!;
    public Content? Content { get; set; }
}
