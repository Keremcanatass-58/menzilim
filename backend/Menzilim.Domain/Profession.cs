namespace Menzilim.Domain;

public class Profession
{
    public Guid Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    public ICollection<Specialization> Specializations { get; set; } = new List<Specialization>();

    public ICollection<ContentProfession> ContentProfessions { get; set; } = new List<ContentProfession>();
}