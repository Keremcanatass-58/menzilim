namespace Menzilim.Domain;

public class ContentSkill
{
    public Guid Id { get; set; }
    public Guid ContentId { get; set; }
    public Guid SkillId { get; set; }

    public Content Content { get; set; } = null!;
    public Skill Skill { get; set; } = null!;
}
