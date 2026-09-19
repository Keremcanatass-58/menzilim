using DomainQuiz = Menzilim.Domain.Quiz;

namespace Menzilim.Application.Services.DailyPlan;

/// <summary>
/// Günlük plandaki Quiz görevi için kullanıcının uzmanlığına uygun quiz'i
/// seçer. Deterministiktir, veritabanına erişmez, AI kullanmaz.
///
/// Aday quiz'ler, kullanıcının uzmanlık skill'lerinden birine bağlı aktif
/// quiz'lerdir. Ortak skill'ler (ör. REST API) birden fazla uzmanlıkta
/// bulunduğundan tek başına skill eşleşmesi belirsizdir; bu yüzden:
///   1) Başlığında/açıklamasında uzmanlık adı geçen aday önceliklidir
///      (DailyPlanContentSelector'daki uzmanlık adı eşleşmesiyle aynı kural).
///   2) Eşitlikte en eski quiz (CreatedAt, sonra Id) seçilir.
/// Aday yoksa null döner; çağıran varsayılan quiz'e düşer.
/// </summary>
public static class DailyPlanQuizSelector
{
    /// <param name="specializationQuizzes">
    /// Kullanıcının uzmanlık skill'lerine bağlı aktif quiz'ler.
    /// </param>
    /// <param name="specializationName">Uzmanlık adı.</param>
    public static DomainQuiz? Select(
        IReadOnlyList<DomainQuiz> specializationQuizzes,
        string? specializationName)
    {
        return specializationQuizzes
            .Where(q => q.IsActive)
            .OrderByDescending(q => SpecializationMatch(q, specializationName))
            .ThenBy(q => q.CreatedAt)
            .ThenBy(q => q.Id)
            .FirstOrDefault();
    }

    private static int SpecializationMatch(DomainQuiz quiz, string? specialization)
    {
        if (string.IsNullOrWhiteSpace(specialization))
        {
            return 0;
        }

        var term = specialization.Trim();

        var inTitle = quiz.Title
            .Contains(term, StringComparison.OrdinalIgnoreCase);

        var inDescription = quiz.Description is not null &&
            quiz.Description.Contains(term, StringComparison.OrdinalIgnoreCase);

        return inTitle || inDescription ? 1 : 0;
    }
}
