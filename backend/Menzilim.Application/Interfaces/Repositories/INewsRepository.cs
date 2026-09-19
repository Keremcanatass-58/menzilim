using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface INewsRepository
{
    /// <summary>
    /// Uzmanlığın aktif skill'lerinden en az birine bağlı aktif haberler;
    /// PublishedAt azalan, eşitlikte Id sırasıyla, en fazla <paramref name="take"/> adet.
    /// </summary>
    Task<List<NewsItem>> GetActiveBySpecializationAsync(Guid specializationId, int take);

    /// <summary>
    /// Mesleğin aktif uzmanlıklarının aktif skill'lerine bağlı aktif haberler;
    /// aynı sıralama ve sınır.
    /// </summary>
    Task<List<NewsItem>> GetActiveByProfessionAsync(Guid professionId, int take);
}
