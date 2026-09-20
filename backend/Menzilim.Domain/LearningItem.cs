namespace Menzilim.Domain;

public class LearningItem
{
    public Guid Id { get; set; }
    public Guid LearningPathId { get; set; }
    public Guid? ContentId { get; set; }

    /// <summary>Adımın büyüttüğü beceri (opsiyonel).</summary>
    public Guid? SkillId { get; set; }

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Order { get; set; }
    public int EstimatedMinutes { get; set; }

    public LearningPath LearningPath { get; set; } = null!;
    public Content? Content { get; set; }
    public Skill? Skill { get; set; }
}
