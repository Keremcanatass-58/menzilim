namespace Menzilim.Application.DTOs.Projects;

/// <summary>Kullanıcının gelişen projesi ve adımları.</summary>
public class UserProjectResponse
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    /// <summary>NotStarted | InProgress | Completed</summary>
    public string Status { get; set; } = string.Empty;

    public int TotalSteps { get; set; }

    public int CompletedSteps { get; set; }

    public int ProgressPercent { get; set; }

    public int TotalMinutes { get; set; }

    public DateTime? StartedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    /// <summary>Sıradaki tamamlanabilir adım (yoksa null).</summary>
    public UserProjectStepResponse? NextStep { get; set; }

    public List<UserProjectStepResponse> Steps { get; set; } = new();
}
