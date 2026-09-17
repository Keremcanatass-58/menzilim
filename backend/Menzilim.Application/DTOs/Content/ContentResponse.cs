namespace Menzilim.Application.DTOs.Content;

public class ContentResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Url { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public int ReadingTimeMinutes { get; set; }
    public string Level { get; set; } = string.Empty;
}
