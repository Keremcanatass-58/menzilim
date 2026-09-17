namespace Menzilim.Domain;

public class UserActivity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ActivityType { get; set; } = string.Empty;
    public string? ReferenceId { get; set; }
    public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
}
