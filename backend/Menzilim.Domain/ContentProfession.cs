namespace Menzilim.Domain;

public class ContentProfession
{
    public Guid Id { get; set; }
    public Guid ContentId { get; set; }
    public Guid ProfessionId { get; set; }

    public Content Content { get; set; } = null!;
    public Profession Profession { get; set; } = null!;
}
