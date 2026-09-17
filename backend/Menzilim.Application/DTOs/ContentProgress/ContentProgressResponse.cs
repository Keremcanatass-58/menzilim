namespace Menzilim.Application.DTOs.ContentProgress;

public class ContentProgressResponse
{
    public Guid ContentId { get; set; }
    public bool IsStarted { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}
