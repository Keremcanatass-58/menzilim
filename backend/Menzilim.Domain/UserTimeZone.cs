namespace Menzilim.Domain;

/// <summary>
/// Gün sınırı hesabı için kullanıcı saat dilimi. Sunucu UTC çalışır;
/// "bugün" kullanıcının yerel gününe göre belirlenir.
/// </summary>
public static class UserTimeZone
{
    /// <summary>Bildirilmemiş kullanıcılar için güvenli varsayılan (UTC+3).</summary>
    public const int DefaultOffsetMinutes = 180;

    /// <summary>Gerçek saat dilimi aralığı: UTC-12 … UTC+14.</summary>
    public static bool IsValid(int offsetMinutes) =>
        offsetMinutes >= -12 * 60 && offsetMinutes <= 14 * 60;

    public static int Normalize(int? offsetMinutes) =>
        offsetMinutes is not null && IsValid(offsetMinutes.Value)
            ? offsetMinutes.Value
            : DefaultOffsetMinutes;

    /// <summary>UTC zamanın kullanıcı yerel saatindeki tarihi (saat bilgisi yok).</summary>
    public static DateOnly LocalDate(DateTime utc, int offsetMinutes) =>
        DateOnly.FromDateTime(
            DateTime.SpecifyKind(utc, DateTimeKind.Utc)
                .AddMinutes(offsetMinutes));
}
