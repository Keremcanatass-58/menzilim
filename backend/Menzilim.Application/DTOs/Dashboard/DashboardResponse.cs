namespace Menzilim.Application.DTOs.Dashboard;

public class DashboardResponse
{
    public Guid UserId { get; set; }

    public string Profession { get; set; } = string.Empty;

    public string Specialization { get; set; } = string.Empty;

    public string ExperienceLevel { get; set; } = string.Empty;

    public string CareerGoal { get; set; } = string.Empty;

    public int DailyLearningMinutes { get; set; }

    // Günlük Plan İlerlemesi
    public int TotalTasks { get; set; }

    public int CompletedTasks { get; set; }

    public int TotalMinutes { get; set; }

    public int CompletedMinutes { get; set; }

    public double DailyProgressPercent { get; set; }

    // İçerik İlerlemesi
    public int CompletedContentCount { get; set; }

    public int InProgressContentCount { get; set; }
}
