namespace Menzilim.Application.DTOs.Projects;

public class UserProjectStepResponse
{
    public Guid Id { get; set; }

    public int Order { get; set; }

    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    /// <summary>Locked | Available | Completed</summary>
    public string Status { get; set; } = string.Empty;

    public int EstimatedMinutes { get; set; }

    public Guid? ContentId { get; set; }

    public string? ContentTitle { get; set; }

    public Guid? SkillId { get; set; }

    public string? SkillName { get; set; }

    public DateTime? CompletedAt { get; set; }

    public string? EvidenceUrl { get; set; }

    public string? Note { get; set; }
}
