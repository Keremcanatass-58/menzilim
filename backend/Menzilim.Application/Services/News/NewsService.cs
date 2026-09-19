using Menzilim.Application.DTOs.News;
using Menzilim.Application.Interfaces.News;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;

namespace Menzilim.Application.Services.News;

/// <summary>
/// Kullanıcının meslek/uzmanlığına göre haber akışı. AI kullanmaz.
///   1) Uzmanlığın skill'lerine bağlı haberler.
///   2) Hiç yoksa, mesleğin uzmanlıklarının skill'lerine bağlı haberler.
///   3) Onboarding yapılmamışsa (profil yok) boş liste.
/// Sıralama (PublishedAt azalan, eşitlikte Id) ve sınır repository'de,
/// veritabanında uygulanır.
/// </summary>
public class NewsService : INewsService
{
    public const int MaxItems = 10;

    private readonly IUserRepository _userRepository;
    private readonly INewsRepository _newsRepository;

    public NewsService(
        IUserRepository userRepository,
        INewsRepository newsRepository)
    {
        _userRepository = userRepository;
        _newsRepository = newsRepository;
    }

    public async Task<List<NewsItemResponse>> GetForUserAsync(Guid userId)
    {
        var profile =
            (await _userRepository.GetByIdWithProfileDetailsAsync(userId))?.Profile;

        if (profile is null)
        {
            return new List<NewsItemResponse>();
        }

        var news = await _newsRepository.GetActiveBySpecializationAsync(
            profile.SpecializationId,
            MaxItems);

        if (news.Count == 0)
        {
            news = await _newsRepository.GetActiveByProfessionAsync(
                profile.ProfessionId,
                MaxItems);
        }

        return news.Select(Map).ToList();
    }

    private static NewsItemResponse Map(NewsItem news) =>
        new()
        {
            Id = news.Id,
            Title = news.Title,
            Summary = news.Summary,
            SourceName = news.SourceName,
            SourceUrl = news.SourceUrl,
            PublishedAt = news.PublishedAt,
            ImageUrl = news.ImageUrl,
        };
}
