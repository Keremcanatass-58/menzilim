namespace Menzilim.Application.DTOs.Content;

public class ContentRecommendationResponse
{
    public Guid ContentId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Url { get; set; } = string.Empty;
    public bool IsStarted { get; set; }
    public bool IsCompleted { get; set; }

    /// <summary>
    /// Kullanıcıya gösterilebilir, Türkçe öneri gerekçesi.
    /// </summary>
    public string RecommendationReason { get; set; } = string.Empty;
}
