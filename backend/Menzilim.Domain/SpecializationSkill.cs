namespace Menzilim.Domain;

public class SpecializationSkill
{
    public Guid Id { get; set; }
    public Guid SpecializationId { get; set; }
    public Guid SkillId { get; set; }

    public Specialization Specialization { get; set; } = null!;
    public Skill Skill { get; set; } = null!;
}
