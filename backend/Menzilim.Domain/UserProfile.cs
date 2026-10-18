namespace Menzilim.Domain;

public class UserProfile
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid ProfessionId { get; set; }

    public Guid SpecializationId { get; set; }

    public string ExperienceLevel { get; set; } = string.Empty;

    public string CareerGoal { get; set; } = string.Empty;

    public int DailyLearningMinutes { get; set; }

    /// <summary>
    /// Kullanıcının UTC farkı (dakika). Gün sınırı bununla hesaplanır;
    /// istemci bildirmediyse Türkiye saati (UTC+3) varsayılır.
    /// </summary>
    public int TimeZoneOffsetMinutes { get; set; } = UserTimeZone.DefaultOffsetMinutes;

    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;

    public Profession Profession { get; set; } = null!;

    public Specialization Specialization { get; set; } = null!;
}