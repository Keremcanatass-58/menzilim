namespace Menzilim.Application.DTOs.Progress;

/// <summary>İstemcinin bildirdiği UTC farkı (dakika).</summary>
public class UpdateTimeZoneRequest
{
    public int OffsetMinutes { get; set; }
}
