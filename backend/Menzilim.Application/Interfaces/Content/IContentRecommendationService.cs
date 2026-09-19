using Menzilim.Application.DTOs.Content;

namespace Menzilim.Application.Interfaces.Content;

public interface IContentRecommendationService
{
    Task<List<ContentRecommendationResponse>> GetForUserAsync(Guid userId);
}
