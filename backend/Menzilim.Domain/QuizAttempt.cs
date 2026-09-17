namespace Menzilim.Domain;

public class QuizAttempt
{
    public Guid Id { get; set; }
    public Guid QuizId { get; set; }
    public Guid UserId { get; set; }
    public int Score { get; set; }
    public int CorrectAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public DateTime CompletedAt { get; set; }

    public Quiz Quiz { get; set; } = null!;
    public User User { get; set; } = null!;
}
