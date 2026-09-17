namespace Menzilim.Application.Interfaces.Repositories;

public interface IContentProfessionRepository
{
    Task<bool> ExistsAsync(Guid contentId, Guid professionId);
    Task AddAsync(Menzilim.Domain.ContentProfession contentProfession);
    Task SaveChangesAsync();
}
