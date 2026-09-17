namespace Menzilim.Domain;

public class DailyPlan
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTime Date { get; set; }
    public string Title { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; }

    public ICollection<DailyTask> Tasks { get; set; } = new List<DailyTask>();
}
