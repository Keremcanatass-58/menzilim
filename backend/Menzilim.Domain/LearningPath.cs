namespace Menzilim.Domain;

public class LearningPath
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Guid ProfessionId { get; set; }
    public Guid? SpecializationId { get; set; }
    public string Level { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public ICollection<LearningItem> Items { get; set; } = new List<LearningItem>();
}
