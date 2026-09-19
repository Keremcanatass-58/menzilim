using Menzilim.Application.DTOs.News;

namespace Menzilim.Application.Interfaces.News;

public interface INewsService
{
    Task<List<NewsItemResponse>> GetForUserAsync(Guid userId);
}
