using Menzilim.Application.DTOs.Content;
using Menzilim.Application.Interfaces.ContentProfession;
using Menzilim.Application.Interfaces.Repositories;

namespace Menzilim.Application.Services.ContentProfession;

public class ContentProfessionService : IContentProfessionService
{
    private readonly IContentProfessionRepository _repository;

    public ContentProfessionService(
        IContentProfessionRepository repository)
    {
        _repository = repository;
    }

    public async Task<bool> AddAsync(
        CreateContentProfessionRequest request)
    {
        if (await _repository.ExistsAsync(
                request.ContentId,
                request.ProfessionId))
        {
            return false;
        }

        var contentProfession = new Menzilim.Domain.ContentProfession
        {
            Id = Guid.NewGuid(),
            ContentId = request.ContentId,
            ProfessionId = request.ProfessionId
        };

        await _repository.AddAsync(contentProfession);
        await _repository.SaveChangesAsync();

        return true;
    }
}
