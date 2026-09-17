using Menzilim.Application.DTOs.Content;
using Menzilim.Application.Interfaces.Content;
using Menzilim.Application.Interfaces.Repositories;

namespace Menzilim.Application.Services.Content;

public class ContentService : IContentService
{
    private readonly IContentRepository _contentRepository;

    public ContentService(IContentRepository contentRepository)
    {
        _contentRepository = contentRepository;
    }

    public async Task<List<ContentResponse>> GetAllAsync()
    {
        var contents = await _contentRepository.GetActiveAsync();

        return contents
            .Select(MapToResponse)
            .ToList();
    }

    public async Task<ContentResponse?> GetByIdAsync(Guid contentId)
    {
        var content = await _contentRepository.GetByIdAsync(contentId);

        return content is null
            ? null
            : MapToResponse(content);
    }

    public async Task<ContentResponse> CreateAsync(
        CreateContentRequest request)
    {
        var content = new Menzilim.Domain.Content
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Description = request.Description,
            Url = request.Url,
            Source = request.Source,
            PublishedAt = request.PublishedAt,
            ReadingTimeMinutes = request.ReadingTimeMinutes,
            Level = request.Level,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        await _contentRepository.AddAsync(content);
        await _contentRepository.SaveChangesAsync();

        return MapToResponse(content);
    }

    public async Task<List<ContentResponse>> GetByProfessionAsync(
        Guid professionId)
    {
        var contents =
            await _contentRepository.GetByProfessionAsync(professionId);

        return contents
            .Select(MapToResponse)
            .ToList();
    }

    private static ContentResponse MapToResponse(
        Menzilim.Domain.Content content)
    {
        return new ContentResponse
        {
            Id = content.Id,
            Title = content.Title,
            Description = content.Description,
            Url = content.Url,
            Source = content.Source,
            PublishedAt = content.PublishedAt,
            ReadingTimeMinutes = content.ReadingTimeMinutes,
            Level = content.Level
        };
    }
}
