namespace Menzilim.Domain;

public class NewsItemSkill
{
    public Guid Id { get; set; }
    public Guid NewsItemId { get; set; }
    public Guid SkillId { get; set; }

    public NewsItem NewsItem { get; set; } = null!;
    public Skill Skill { get; set; } = null!;
}
