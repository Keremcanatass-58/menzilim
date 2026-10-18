using Menzilim.Application.DTOs.Progress;
using Menzilim.Application.Interfaces.Progress;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Progress;

/// <summary>
/// Süreklilik: kullanıcının gerçek aktivitelerinden (tamamlanan içerik,
/// quiz denemesi, tamamlanan proje adımı) hesaplanır. Ayrı bir aktivite
/// kaydı tutulmaz; kaynak mevcut tablolardır, bu yüzden çift sayım olmaz.
/// Sonuç UserProgress'e yazılır.
/// </summary>
public class StreakService : IStreakService
{
    private readonly IUserRepository _userRepository;
    private readonly IUserContentProgressRepository _contentProgressRepository;
    private readonly IQuizRepository _quizRepository;
    private readonly IUserProjectRepository _projectRepository;
    private readonly IUserProgressRepository _progressRepository;

    public StreakService(
        IUserRepository userRepository,
        IUserContentProgressRepository contentProgressRepository,
        IQuizRepository quizRepository,
        IUserProjectRepository projectRepository,
        IUserProgressRepository progressRepository)
    {
        _userRepository = userRepository;
        _contentProgressRepository = contentProgressRepository;
        _quizRepository = quizRepository;
        _projectRepository = projectRepository;
        _progressRepository = progressRepository;
    }

    public async Task<StreakResponse> GetForUserAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user is null)
        {
            throw new KeyNotFoundException("Kullanıcı bulunamadı.");
        }

        var offset = UserTimeZone.Normalize(user.Profile?.TimeZoneOffsetMinutes);

        var activities = await CollectActivityTimesAsync(userId);

        var result = StreakEngine.Calculate(
            activities,
            offset,
            DateTime.UtcNow);

        await PersistAsync(userId, result);

        return new StreakResponse
        {
            CurrentStreak = result.CurrentStreak,
            LongestStreak = result.LongestStreak,
            IsActiveToday = result.IsActiveToday,
            LastActiveDate = result.LastActiveDate?.ToString("yyyy-MM-dd"),
            TimeZoneOffsetMinutes = offset,
        };
    }

    public async Task<int> UpdateTimeZoneAsync(Guid userId, int offsetMinutes)
    {
        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user?.Profile is null)
        {
            throw new KeyNotFoundException("Kullanıcı profili bulunamadı.");
        }

        // Geçersiz değer yok sayılır; mevcut ayar korunur.
        if (UserTimeZone.IsValid(offsetMinutes) &&
            user.Profile.TimeZoneOffsetMinutes != offsetMinutes)
        {
            user.Profile.TimeZoneOffsetMinutes = offsetMinutes;
            user.Profile.UpdatedAt = DateTime.UtcNow;

            await _userRepository.SaveChangesAsync();
        }

        return user.Profile.TimeZoneOffsetMinutes;
    }

    /// <summary>
    /// Aktivite zamanları: yalnızca tamamlanma anları sayılır. "Başlandı"
    /// kayıtları (içeriğin açılması) aktivite sayılmaz.
    /// </summary>
    private async Task<List<DateTime>> CollectActivityTimesAsync(Guid userId)
    {
        var times = new List<DateTime>();

        var contentProgress =
            await _contentProgressRepository.GetByUserAsync(userId);

        times.AddRange(contentProgress
            .Where(p => p.IsCompleted && p.CompletedAt is not null)
            .Select(p => p.CompletedAt!.Value));

        var attempts = await _quizRepository.GetByUserAsync(userId);

        times.AddRange(attempts.Select(a => a.CompletedAt));

        var projects = await _projectRepository.GetByUserAsync(userId);

        times.AddRange(projects
            .SelectMany(p => p.Steps)
            .Where(s => s.CompletedAt is not null)
            .Select(s => s.CompletedAt!.Value));

        return times;
    }

    private async Task PersistAsync(
        Guid userId,
        StreakEngine.StreakResult result)
    {
        var progress = await _progressRepository.GetByUserAsync(userId);

        if (progress is null)
        {
            progress = new UserProgress
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                UpdatedAt = DateTime.UtcNow,
            };

            await _progressRepository.AddAsync(progress);
        }

        var changed =
            progress.CurrentStreak != result.CurrentStreak ||
            progress.LongestStreak != result.LongestStreak;

        progress.CurrentStreak = result.CurrentStreak;

        // Kayıtlı en uzun seri geriye gitmez.
        progress.LongestStreak =
            Math.Max(progress.LongestStreak, result.LongestStreak);

        if (changed)
        {
            progress.UpdatedAt = DateTime.UtcNow;
        }

        await _progressRepository.SaveChangesAsync();
    }
}
