namespace Menzilim.Application.DTOs.Progress;

/// <summary>
/// Süreklilik özeti. Gün sınırı kullanıcının saat dilimine göre hesaplanır.
/// </summary>
public class StreakResponse
{
    /// <summary>Ardışık aktif gün sayısı (bugün veya dün aktifse sürüyor).</summary>
    public int CurrentStreak { get; set; }

    /// <summary>Kullanıcının gördüğü en uzun seri.</summary>
    public int LongestStreak { get; set; }

    /// <summary>Kullanıcının yerel gününde bugün aktivite var mı?</summary>
    public bool IsActiveToday { get; set; }

    /// <summary>Son aktif gün (kullanıcı yerel tarihi, yyyy-MM-dd).</summary>
    public string? LastActiveDate { get; set; }

    /// <summary>Hesapta kullanılan UTC farkı (dakika).</summary>
    public int TimeZoneOffsetMinutes { get; set; }
}
