namespace Menzilim.Domain;

public class UserProgress
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int TotalLearningMinutes { get; set; }
    public int CompletedTasks { get; set; }
    public int CompletedQuizzes { get; set; }
    public int CurrentStreak { get; set; }
    public int LongestStreak { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
}
