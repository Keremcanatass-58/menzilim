using Menzilim.Application.DTOs.ContentProgress;
using Menzilim.Application.Interfaces.Content;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;

namespace Menzilim.Application.Services;

public class ContentProgressService : IContentProgressService
{
    private readonly IUserContentProgressRepository _progressRepository;
    private readonly IContentRepository _contentRepository;

    public ContentProgressService(
        IUserContentProgressRepository progressRepository,
        IContentRepository contentRepository)
    {
        _progressRepository = progressRepository;
        _contentRepository = contentRepository;
    }

    public async Task<ContentProgressResponse> StartAsync(
        Guid userId,
        Guid contentId)
    {
        var content = await _contentRepository.GetByIdAsync(contentId);

        if (content is null)
            throw new KeyNotFoundException("İçerik bulunamadı.");

        var progress = await _progressRepository.GetAsync(
            userId,
            contentId);

        if (progress is null)
        {
            progress = new UserContentProgress
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ContentId = contentId,
                StartedAt = DateTime.UtcNow,
                IsCompleted = false
            };

            await _progressRepository.AddAsync(progress);
            await _progressRepository.SaveChangesAsync();
        }

        return Map(progress);
    }

    public async Task<ContentProgressResponse> CompleteAsync(
        Guid userId,
        Guid contentId)
    {
        var content = await _contentRepository.GetByIdAsync(contentId);

        if (content is null)
            throw new KeyNotFoundException("İçerik bulunamadı.");

        var progress = await _progressRepository.GetAsync(
            userId,
            contentId);

        if (progress is null)
        {
            progress = new UserContentProgress
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ContentId = contentId,
                StartedAt = DateTime.UtcNow
            };

            await _progressRepository.AddAsync(progress);
        }

        progress.IsCompleted = true;
        progress.CompletedAt ??= DateTime.UtcNow;

        await _progressRepository.SaveChangesAsync();

        return Map(progress);
    }

    public async Task<ContentProgressResponse?> GetAsync(
        Guid userId,
        Guid contentId)
    {
        var content = await _contentRepository.GetByIdAsync(contentId);

        if (content is null)
            throw new KeyNotFoundException("İçerik bulunamadı.");

        var progress = await _progressRepository.GetAsync(
            userId,
            contentId);

        if (progress is null)
            return null;

        return Map(progress);
    }

    private static ContentProgressResponse Map(
        UserContentProgress progress)
    {
        return new ContentProgressResponse
        {
            ContentId = progress.ContentId,
            IsStarted = true,
            IsCompleted = progress.IsCompleted,
            StartedAt = progress.StartedAt,
            CompletedAt = progress.CompletedAt
        };
    }
}
