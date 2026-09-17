using Menzilim.Application.DTOs.ContentProgress;

namespace Menzilim.Application.Interfaces.Content;

public interface IContentProgressService
{
    Task<ContentProgressResponse> StartAsync(Guid userId, Guid contentId);
    Task<ContentProgressResponse> CompleteAsync(Guid userId, Guid contentId);
    Task<ContentProgressResponse?> GetAsync(Guid userId, Guid contentId);
}
