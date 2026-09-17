namespace Menzilim.Application.DTOs.DailyPlan;

public class DailyPlanResponse
{
    public Guid Id { get; set; }
    public DateTime Date { get; set; }
    public string Title { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public int TotalMinutes { get; set; }
    public int CompletedMinutes { get; set; }
    public List<DailyTaskResponse> Tasks { get; set; } = new();
}

public class DailyTaskResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string TaskType { get; set; } = string.Empty;
    public int EstimatedMinutes { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
}
