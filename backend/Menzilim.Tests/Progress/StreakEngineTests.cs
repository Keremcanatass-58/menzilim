using Menzilim.Application.Services.Progress;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.Progress;

/// <summary>
/// Süreklilik hesabı: gün sınırı kullanıcı saatine göre, bir gün en fazla
/// bir streak günü.
/// </summary>
public class StreakEngineTests
{
    // Türkiye: UTC+3.
    private const int TurkeyOffset = 180;

    private static DateTime Utc(int year, int month, int day, int hour = 12) =>
        new(year, month, day, hour, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void NoActivity_ReturnsZero()
    {
        var result = StreakEngine.Calculate(
            Array.Empty<DateTime>(),
            TurkeyOffset,
            Utc(2026, 3, 10));

        Assert.Equal(0, result.CurrentStreak);
        Assert.Equal(0, result.LongestStreak);
        Assert.False(result.IsActiveToday);
        Assert.Null(result.LastActiveDate);
    }

    [Fact]
    public void SameDayActivities_CountAsOneDay()
    {
        var activities = new[]
        {
            Utc(2026, 3, 10, 6),
            Utc(2026, 3, 10, 9),
            Utc(2026, 3, 10, 15),
            Utc(2026, 3, 10, 20),
        };

        var result = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 10, 18));

        Assert.Equal(1, result.CurrentStreak);
        Assert.Equal(1, result.LongestStreak);
        Assert.True(result.IsActiveToday);
    }

    [Fact]
    public void ConsecutiveDays_IncreaseStreak()
    {
        var activities = new[]
        {
            Utc(2026, 3, 8),
            Utc(2026, 3, 9),
            Utc(2026, 3, 10),
        };

        var result = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 10, 20));

        Assert.Equal(3, result.CurrentStreak);
        Assert.Equal(3, result.LongestStreak);
        Assert.True(result.IsActiveToday);
    }

    [Fact]
    public void ActiveYesterdayOnly_StreakStillRunning()
    {
        var activities = new[]
        {
            Utc(2026, 3, 8),
            Utc(2026, 3, 9),
        };

        // Bugün henüz aktivite yok.
        var result = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 10, 9));

        Assert.Equal(2, result.CurrentStreak);
        Assert.False(result.IsActiveToday);
    }

    [Fact]
    public void MissedDay_ResetsCurrentStreak_ButKeepsLongest()
    {
        var activities = new[]
        {
            Utc(2026, 3, 1),
            Utc(2026, 3, 2),
            Utc(2026, 3, 3),
            // 4-8 arası boşluk
            Utc(2026, 3, 9, 3),
        };

        // 9 Mart 03:00 UTC = 9 Mart 06:00 TR; bugün 11 Mart.
        var result = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 11, 10));

        Assert.Equal(0, result.CurrentStreak);
        Assert.Equal(3, result.LongestStreak);
        Assert.False(result.IsActiveToday);
        Assert.Equal(new DateOnly(2026, 3, 9), result.LastActiveDate);
    }

    [Fact]
    public void TimeZone_ChangesDayBoundary()
    {
        // 9 Mart 22:00 UTC = 10 Mart 01:00 Türkiye saati.
        var activities = new[] { Utc(2026, 3, 9, 22) };

        var turkey = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 10, 8));

        // Türkiye'de bugün aktif sayılır.
        Assert.True(turkey.IsActiveToday);
        Assert.Equal(new DateOnly(2026, 3, 10), turkey.LastActiveDate);

        var utc = StreakEngine.Calculate(activities, 0, Utc(2026, 3, 10, 8));

        // UTC'de dün sayılır: seri sürüyor ama bugün aktif değil.
        Assert.False(utc.IsActiveToday);
        Assert.Equal(1, utc.CurrentStreak);
        Assert.Equal(new DateOnly(2026, 3, 9), utc.LastActiveDate);
    }

    [Fact]
    public void InvalidOffset_FallsBackToDefault()
    {
        var activities = new[] { Utc(2026, 3, 9, 22) };

        var result = StreakEngine.Calculate(
            activities,
            offsetMinutes: 9999,
            Utc(2026, 3, 10, 8));

        // Varsayılan (UTC+3) ile aynı sonuç.
        Assert.True(result.IsActiveToday);
        Assert.Equal(UserTimeZone.DefaultOffsetMinutes, UserTimeZone.Normalize(9999));
    }

    [Fact]
    public void LongestStreak_IsFoundInHistory()
    {
        var activities = new[]
        {
            // 5 günlük seri
            Utc(2026, 2, 1), Utc(2026, 2, 2), Utc(2026, 2, 3),
            Utc(2026, 2, 4), Utc(2026, 2, 5),
            // boşluk, sonra bugün
            Utc(2026, 3, 10),
        };

        var result = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 10, 20));

        Assert.Equal(1, result.CurrentStreak);
        Assert.Equal(5, result.LongestStreak);
    }

    [Fact]
    public void FutureActivity_DoesNotInflateStreak()
    {
        // Saat kayması nedeniyle ileri tarihli kayıt.
        var activities = new[] { Utc(2026, 3, 12), Utc(2026, 3, 10) };

        var result = StreakEngine.Calculate(
            activities,
            TurkeyOffset,
            Utc(2026, 3, 10, 20));

        Assert.True(result.CurrentStreak >= 1);
        Assert.True(result.CurrentStreak <= 2);
        Assert.True(result.IsActiveToday);
    }
}
