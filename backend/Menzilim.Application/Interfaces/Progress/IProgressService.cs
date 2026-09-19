using Menzilim.Application.DTOs.Progress;

namespace Menzilim.Application.Interfaces.Progress;

public interface IProgressService
{
    Task<ProgressResponse> GetMyProgressAsync(Guid userId);
}