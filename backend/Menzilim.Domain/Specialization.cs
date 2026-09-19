namespace Menzilim.Domain;

public class Specialization
{
    public Guid Id { get; set; }

    public Guid ProfessionId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    public Profession Profession { get; set; } = null!;

    public ICollection<UserProfile> UserProfiles { get; set; } = new List<UserProfile>();

    public ICollection<SpecializationSkill> SpecializationSkills { get; set; } = new List<SpecializationSkill>();
}