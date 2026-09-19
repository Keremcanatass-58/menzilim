namespace Menzilim.Domain;

/// <summary>
/// Güncel teknoloji haberi/duyurusu. Öğrenme içeriği olan <see cref="Content"/>
/// ile karıştırılmaz. Haberin tamamı tutulmaz; kısa özet ve orijinal kaynağa
/// yönlendiren URL saklanır.
/// </summary>
public class NewsItem
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Summary { get; set; } = string.Empty;

    public string SourceName { get; set; } = string.Empty;

    // Orijinal kaynak; benzersizdir (seed ve ileride feed alımı için doğal anahtar).
    public string SourceUrl { get; set; } = string.Empty;

    public DateTime PublishedAt { get; set; }

    public string? ImageUrl { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    public ICollection<NewsItemSkill> Skills { get; set; } = new List<NewsItemSkill>();
}
