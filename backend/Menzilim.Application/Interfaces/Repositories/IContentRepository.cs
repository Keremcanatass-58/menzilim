namespace Menzilim.Application.Interfaces.Repositories;

public interface IContentRepository
{
    Task<List<Menzilim.Domain.Content>> GetActiveAsync();

    Task<Menzilim.Domain.Content?> GetByIdAsync(Guid contentId);

    Task<List<Menzilim.Domain.Content>> GetByProfessionAsync(
        Guid professionId);

    Task AddAsync(Menzilim.Domain.Content content);

    Task SaveChangesAsync();
}
