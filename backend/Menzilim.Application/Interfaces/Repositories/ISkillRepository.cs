using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface ISkillRepository
{
    Task<bool> SpecializationExistsAsync(Guid specializationId);

    /// <summary>Uzmanlığa bağlı aktif skill'ler.</summary>
    Task<List<Skill>> GetActiveBySpecializationAsync(Guid specializationId);

    /// <summary>Verilen skill'lere bağlı, aktif içeriklerin ilişkileri.</summary>
    Task<List<ContentSkill>> GetActiveContentLinksAsync(
        IReadOnlyCollection<Guid> skillIds);

    /// <summary>Verilen skill'lere bağlı aktif quiz'ler.</summary>
    Task<List<Menzilim.Domain.Quiz>> GetActiveQuizzesAsync(
        IReadOnlyCollection<Guid> skillIds);

    /// <summary>Kullanıcının yalnızca verilen quiz'lere ait denemeleri.</summary>
    Task<List<QuizAttempt>> GetUserQuizAttemptsAsync(
        Guid userId,
        IReadOnlyCollection<Guid> quizIds);
}
