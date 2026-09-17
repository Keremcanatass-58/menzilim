namespace Menzilim.Domain;

public class ContentTag
{
    public Guid Id { get; set; }
    public Guid ContentId { get; set; }
    public string Tag { get; set; } = string.Empty;

    public Content Content { get; set; } = null!;
}
