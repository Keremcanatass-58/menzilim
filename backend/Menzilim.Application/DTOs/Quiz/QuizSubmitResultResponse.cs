namespace Menzilim.Application.DTOs.Quiz;

public class QuizSubmitResultResponse
{
    public Guid AttemptId { get; set; }
    public Guid QuizId { get; set; }
    public int Score { get; set; }
    public int CorrectAnswers { get; set; }
    public int WrongAnswers { get; set; }
    public int TotalQuestions { get; set; }
    public double SuccessRate { get; set; }
}
