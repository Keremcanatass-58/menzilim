namespace Menzilim.Domain;

public class Skill
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string Category { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    public ICollection<UserSkill> UserSkills { get; set; } = new List<UserSkill>();

    public ICollection<SpecializationSkill> SpecializationSkills { get; set; } = new List<SpecializationSkill>();

    public ICollection<ContentSkill> ContentSkills { get; set; } = new List<ContentSkill>();

    public ICollection<Quiz> Quizzes { get; set; } = new List<Quiz>();
}