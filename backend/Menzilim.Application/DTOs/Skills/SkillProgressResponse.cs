namespace Menzilim.Application.DTOs.Skills;

public class SkillProgressResponse
{
    public Guid SkillId { get; set; }
    public string SkillName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;

    /// <summary>
    /// 0-100 arası skill ilerlemesi (SkillProgressEngine formülü).
    /// </summary>
    public int ProgressPercent { get; set; }

    // İçerik aktivitesi
    public int TotalContentCount { get; set; }
    public int CompletedContentCount { get; set; }
    public int InProgressContentCount { get; set; }

    // Quiz aktivitesi
    public int TotalQuizCount { get; set; }
    public int AttemptedQuizCount { get; set; }
    public int QuizAttemptCount { get; set; }

    /// <summary>Kullanıcının bu skill'e bağlı quiz'lerdeki en yüksek skoru (0-100).</summary>
    public int? BestQuizScore { get; set; }

    /// <summary>En son quiz denemesinin skoru (gösterim amaçlı).</summary>
    public int? LatestQuizScore { get; set; }
}
