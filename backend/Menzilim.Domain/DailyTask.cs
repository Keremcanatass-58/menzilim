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

    public DailyPlan DailyPlan { get; set; } = null!;
}
