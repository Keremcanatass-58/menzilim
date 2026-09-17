namespace Menzilim.Domain;

public class UserContentProgress
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid ContentId { get; set; }

    public DateTime StartedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    public bool IsCompleted { get; set; }

    public User User { get; set; } = null!;

    public Content Content { get; set; } = null!;
}