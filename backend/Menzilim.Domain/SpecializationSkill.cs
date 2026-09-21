namespace Menzilim.Domain;

public class SpecializationSkill
{
    public Guid Id { get; set; }
    public Guid SpecializationId { get; set; }
    public Guid SkillId { get; set; }

    /// <summary>
    /// Bu uzmanlığın yolunda hedeflenen seviye (bkz. <see cref="SkillLevels"/>).
    /// İşe alım vaadi değil, MENZİLİM yolundaki hedeftir.
    /// </summary>
    public string TargetLevel { get; set; } = SkillLevels.Intermediate;

    public Specialization Specialization { get; set; } = null!;
    public Skill Skill { get; set; } = null!;
}
