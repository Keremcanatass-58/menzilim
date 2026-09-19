    namespace Menzilim.Application.DTOs.Progress;

public class ProgressResponse
{
    public ProgressOverview Overview { get; set; } = new();
    public ProgressToday Today { get; set; } = new();
    public ProgressContent Content { get; set; } = new();
    public ProgressQuiz Quiz { get; set; } = new();
    public ProgressSkills Skills { get; set; } = new();
}

public class ProgressOverview
{
    public int CompletedTaskCount { get; set; }
    public int EstimatedLearningMinutes { get; set; }
    public int CompletedPlanCount { get; set; }
    public int ActiveDayCount { get; set; }
}

public class ProgressToday
{
    public bool HasPlan { get; set; }
    public int TotalTasks { get; set; }
    public int CompletedTasks { get; set; }
    public int TotalMinutes { get; set; }
    public int CompletedMinutes { get; set; }
    public int ProgressPercent { get; set; }
}

public class ProgressContent
{
    public int CompletedCount { get; set; }
    public int InProgressCount { get; set; }
}

public class ProgressQuiz
{
    public int AttemptCount { get; set; }
    public int DistinctQuizCount { get; set; }
    public int? BestScore { get; set; }
    public int? AverageScore { get; set; }
    public int? LatestScore { get; set; }
    public DateTime? LatestAttemptAt { get; set; }
}

public class ProgressSkills
{
    public int TotalCount { get; set; }
    public int StartedCount { get; set; }
    public List<SkillProgressSnapshot> Strongest { get; set; } = new();
    public List<SkillProgressSnapshot> Focus { get; set; } = new();
}

public class SkillProgressSnapshot
{
    public Guid SkillId { get; set; }
    public string SkillName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public int ProgressPercent { get; set; }
    public int TotalContentCount { get; set; }
    public int CompletedContentCount { get; set; }
    public int TotalQuizCount { get; set; }
    public int AttemptedQuizCount { get; set; }
}