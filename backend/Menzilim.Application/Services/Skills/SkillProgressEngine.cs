using Menzilim.Application.DTOs.Skills;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Skills;

/// <summary>
/// Kullanıcının skill ilerlemesini mevcut aktivite verilerinden deterministik
/// olarak hesaplar. Veritabanına erişmez, hiçbir şey yazmaz; AI kullanmaz.
///
/// Formül (her skill için):
///   ContentPercent = tamamlanan içerik / skill'e bağlı içerik × 100
///   QuizPercent    = skill'e bağlı her quiz için kullanıcının EN İYİ skoru;
///                    denenmemiş quiz 0 sayılır; bunların ortalaması
///   ProgressPercent:
///     - hem içerik hem quiz varsa  → (ContentPercent + QuizPercent) / 2
///     - yalnızca biri varsa        → o bileşen
///     - hiçbiri yoksa              → 0
///   Sonuç yuvarlanır (MidpointRounding.AwayFromZero) ve 0-100 aralığına sıkıştırılır.
///
/// Devam eden (tamamlanmamış) içerik ilerlemeye katkı sağlamaz; yalnızca
/// sayılır. ContentDetailScreen içerik açılır açılmaz /start çağırdığı için
/// "başlandı" kaydı öğrenmeyi değil, içeriğin açıldığını gösterir.
/// </summary>
public static class SkillProgressEngine
{
    /// <param name="userId">Hesaplanan kullanıcı; diğer kullanıcıların kayıtları yok sayılır.</param>
    /// <param name="specializationSkills">
    /// Kullanıcının uzmanlığına bağlı skill'ler. Yalnızca bunlar hesaplanır.
    /// </param>
    /// <param name="contentSkills">İçerik ↔ skill ilişkileri.</param>
    /// <param name="contentProgress">Kullanıcının içerik ilerleme kayıtları.</param>
    /// <param name="quizzes">Quiz'ler (SkillId'si null olanlar katkı sağlamaz).</param>
    /// <param name="quizAttempts">Kullanıcının quiz denemeleri.</param>
    public static List<SkillProgressResponse> Calculate(
        Guid userId,
        IReadOnlyList<Skill> specializationSkills,
        IReadOnlyList<ContentSkill> contentSkills,
        IReadOnlyList<UserContentProgress> contentProgress,
        IReadOnlyList<Menzilim.Domain.Quiz> quizzes,
        IReadOnlyList<QuizAttempt> quizAttempts)
    {
        // İçerik durumu: aynı içerik için birden fazla kayıt olsa da tek
        // içerik sayılır. Herhangi bir kayıt tamamlanmışsa içerik tamamlanmıştır.
        var progressByContent = contentProgress
            .Where(p => p.UserId == userId)
            .GroupBy(p => p.ContentId)
            .ToDictionary(
                g => g.Key,
                g => g.Any(p => p.IsCompleted || p.CompletedAt is not null));

        // Quiz başına kullanıcının denemeleri.
        var attemptsByQuiz = quizAttempts
            .Where(a => a.UserId == userId)
            .GroupBy(a => a.QuizId)
            .ToDictionary(g => g.Key, g => g.ToList());

        return specializationSkills
            .GroupBy(s => s.Id)
            .Select(g => g.First())
            .Select(skill => CalculateForSkill(
                skill, contentSkills, progressByContent, quizzes, attemptsByQuiz))
            .OrderBy(r => r.SkillName, StringComparer.Ordinal)
            .ThenBy(r => r.SkillId)
            .ToList();
    }

    private static SkillProgressResponse CalculateForSkill(
        Skill skill,
        IReadOnlyList<ContentSkill> contentSkills,
        IReadOnlyDictionary<Guid, bool> progressByContent,
        IReadOnlyList<Menzilim.Domain.Quiz> quizzes,
        IReadOnlyDictionary<Guid, List<QuizAttempt>> attemptsByQuiz)
    {
        // İçerik bileşeni
        var contentIds = contentSkills
            .Where(cs => cs.SkillId == skill.Id)
            .Select(cs => cs.ContentId)
            .ToHashSet();

        var completed = contentIds.Count(id =>
            progressByContent.TryGetValue(id, out var isCompleted) && isCompleted);

        var inProgress = contentIds.Count(id =>
            progressByContent.TryGetValue(id, out var isCompleted) && !isCompleted);

        double? contentPercent = contentIds.Count > 0
            ? (double)completed / contentIds.Count * 100
            : null;

        // Quiz bileşeni
        var skillQuizIds = quizzes
            .Where(q => q.SkillId == skill.Id)
            .Select(q => q.Id)
            .ToHashSet();

        var skillAttempts = skillQuizIds
            .Where(attemptsByQuiz.ContainsKey)
            .SelectMany(id => attemptsByQuiz[id])
            .ToList();

        var bestScoreByQuiz = skillQuizIds.ToDictionary(
            id => id,
            id => attemptsByQuiz.TryGetValue(id, out var attempts)
                ? attempts.Max(a => ClampScore(a.Score))
                : 0);

        double? quizPercent = skillQuizIds.Count > 0
            ? bestScoreByQuiz.Values.Average()
            : null;

        var latestAttempt = skillAttempts
            .OrderByDescending(a => a.CompletedAt)
            .ThenByDescending(a => a.Id)
            .FirstOrDefault();

        return new SkillProgressResponse
        {
            SkillId = skill.Id,
            SkillName = skill.Name,
            Category = skill.Category,
            ProgressPercent = Combine(contentPercent, quizPercent),
            TotalContentCount = contentIds.Count,
            CompletedContentCount = completed,
            InProgressContentCount = inProgress,
            TotalQuizCount = skillQuizIds.Count,
            AttemptedQuizCount = skillQuizIds.Count(attemptsByQuiz.ContainsKey),
            QuizAttemptCount = skillAttempts.Count,
            BestQuizScore = skillAttempts.Count > 0
                ? skillAttempts.Max(a => ClampScore(a.Score))
                : null,
            LatestQuizScore = latestAttempt is null
                ? null
                : ClampScore(latestAttempt.Score),
        };
    }

    private static int Combine(double? contentPercent, double? quizPercent)
    {
        double value = (contentPercent, quizPercent) switch
        {
            (double c, double q) => (c + q) / 2,
            (double c, null) => c,
            (null, double q) => q,
            _ => 0,
        };

        var rounded = (int)Math.Round(value, MidpointRounding.AwayFromZero);

        return Math.Clamp(rounded, 0, 100);
    }

    // QuizService Score'u 0-100 arası yüzde olarak üretir; bozuk veriye karşı sıkıştırılır.
    private static int ClampScore(int score) => Math.Clamp(score, 0, 100);
}
