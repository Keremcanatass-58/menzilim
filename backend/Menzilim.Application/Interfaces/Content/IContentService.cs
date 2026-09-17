using Menzilim.Application.DTOs.Content;

namespace Menzilim.Application.Interfaces.Content;

public interface IContentService
{
    Task<List<ContentResponse>> GetAllAsync();

    Task<ContentResponse?> GetByIdAsync(Guid contentId);

    Task<ContentResponse> CreateAsync(CreateContentRequest request);

    Task<List<ContentResponse>> GetByProfessionAsync(Guid professionId);
}
