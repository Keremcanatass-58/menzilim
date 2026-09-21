namespace Menzilim.Domain;

/// <summary>
/// MENZİLİM öğrenme yolundaki beceri seviyeleri. Kullanıcı profilindeki
/// deneyim seviyesiyle aynı değerleri kullanır (Beginner/Intermediate/Advanced).
/// </summary>
public static class SkillLevels
{
    public const string None = "None";
    public const string Beginner = "Beginner";
    public const string Intermediate = "Intermediate";
    public const string Advanced = "Advanced";

    /// <summary>Seviye sırası; karşılaştırma için kullanılır.</summary>
    public static int Rank(string? level) => level?.Trim().ToLowerInvariant() switch
    {
        "beginner" => 1,
        "intermediate" => 2,
        "advanced" => 3,
        _ => 0,
    };

    /// <summary>
    /// Beceri ilerlemesinin (0-100) karşılık geldiği seviye. Eşikler
    /// <see cref="ProgressFor"/> ile simetriktir.
    /// </summary>
    public static string FromProgress(int progressPercent) => progressPercent switch
    {
        >= 80 => Advanced,
        >= 40 => Intermediate,
        > 0 => Beginner,
        _ => None,
    };

    /// <summary>Bir seviyeye ulaşmak için gereken ilerleme eşiği (0-100).</summary>
    public static int ProgressFor(string? level) => Rank(level) switch
    {
        3 => 80,
        2 => 40,
        1 => 1,
        _ => 0,
    };
}
