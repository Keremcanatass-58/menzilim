namespace Menzilim.Domain;

public class Content
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Url { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public int ReadingTimeMinutes { get; set; }
    public string Level { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public ICollection<ContentTag> Tags { get; set; } = new List<ContentTag>();
    public ICollection<ContentProfession> Professions { get; set; } = new List<ContentProfession>();
    public ICollection<ContentSkill> Skills { get; set; } = new List<ContentSkill>();
}
