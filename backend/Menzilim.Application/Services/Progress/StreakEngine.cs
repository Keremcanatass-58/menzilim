using Menzilim.Domain;

namespace Menzilim.Application.Services.Progress;

/// <summary>
/// Kullanıcının süreklilik (streak) hesabı. Gerçek aktivite zamanlarından
/// deterministik olarak hesaplar; veritabanına erişmez, yazmaz.
///
/// Kurallar:
///   - Bir gün en fazla bir streak günü sayılır (aynı gün 10 aktivite = 1 gün).
///   - Gün sınırı kullanıcının yerel saatine göredir (UTC değil).
///   - Seri bugün veya dün aktifse sürer; iki gün boşluk seriyi bitirir.
///   - Aktivite yoksa 0 döner (uydurma değer üretilmez).
/// </summary>
public static class StreakEngine
{
    public sealed record StreakResult(
        int CurrentStreak,
        int LongestStreak,
        bool IsActiveToday,
        DateOnly? LastActiveDate);

    public static StreakResult Calculate(
        IEnumerable<DateTime> activityTimesUtc,
        int offsetMinutes,
        DateTime nowUtc)
    {
        var offset = UserTimeZone.Normalize(offsetMinutes);

        var days = activityTimesUtc
            .Select(time => UserTimeZone.LocalDate(time, offset))
            .Distinct()
            .OrderBy(day => day)
            .ToList();

        if (days.Count == 0)
        {
            return new StreakResult(0, 0, false, null);
        }

        var today = UserTimeZone.LocalDate(nowUtc, offset);
        var yesterday = today.AddDays(-1);

        // En uzun seri: ardışık günleri tara.
        var longest = 1;
        var run = 1;

        for (var index = 1; index < days.Count; index++)
        {
            run = days[index] == days[index - 1].AddDays(1) ? run + 1 : 1;

            if (run > longest)
            {
                longest = run;
            }
        }

        var lastDay = days[^1];

        // Gelecek tarihli kayıt (saat farkı kayması) seriyi şişirmesin.
        if (lastDay > today)
        {
            lastDay = today;
        }

        // Güncel seri yalnızca bugün ya da dün aktifse sürüyordur.
        var current = 0;

        if (lastDay == today || lastDay == yesterday)
        {
            current = 1;
            var expected = lastDay.AddDays(-1);

            for (var index = days.Count - 2; index >= 0; index--)
            {
                if (days[index] != expected)
                {
                    break;
                }

                current++;
                expected = expected.AddDays(-1);
            }
        }

        if (current > longest)
        {
            longest = current;
        }

        return new StreakResult(
            current,
            longest,
            days.Contains(today),
            days[^1]);
    }
}
