namespace Menzilim.Domain;

public class UserSkill
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid SkillId { get; set; }
    public int Level { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Skill Skill { get; set; } = null!;
}
