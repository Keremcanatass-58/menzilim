using Menzilim.Application.DTOs.Content;

namespace Menzilim.Application.Interfaces.ContentProfession;

public interface IContentProfessionService
{
    Task<bool> AddAsync(CreateContentProfessionRequest request);
}
