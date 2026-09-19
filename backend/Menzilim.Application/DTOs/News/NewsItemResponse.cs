namespace Menzilim.Application.DTOs.News;

public class NewsItemResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public string SourceName { get; set; } = string.Empty;
    public string SourceUrl { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public string? ImageUrl { get; set; }
}
