using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Interfaces.Skills;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Skills;

public class SkillService : ISkillService
{
    private readonly IUserRepository _userRepository;
    private readonly ISkillRepository _skillRepository;
    private readonly IUserContentProgressRepository _progressRepository;

    public SkillService(
        IUserRepository userRepository,
        ISkillRepository skillRepository,
        IUserContentProgressRepository progressRepository)
    {
        _userRepository = userRepository;
        _skillRepository = skillRepository;
        _progressRepository = progressRepository;
    }

    public async Task<List<SkillProgressResponse>> GetMyProgressAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);

        if (user is null)
            throw new KeyNotFoundException("Kullanıcı bulunamadı.");

        var profile = user.Profile;

        if (profile is null)
            throw new KeyNotFoundException("Kullanıcı profili bulunamadı.");

        // Yalnızca uzmanlığa bağlı aktif skill'ler hesaplanır.
        var skills =
            await _skillRepository.GetActiveBySpecializationAsync(profile.SpecializationId);

        if (skills.Count == 0)
            return new List<SkillProgressResponse>();

        var skillIds = skills.Select(s => s.Id).ToList();

        var contentLinks =
            await _skillRepository.GetActiveContentLinksAsync(skillIds);
        var quizzes =
            await _skillRepository.GetActiveQuizzesAsync(skillIds);

        var quizAttempts = quizzes.Count == 0
            ? new List<QuizAttempt>()
            : await _skillRepository.GetUserQuizAttemptsAsync(
                userId,
                quizzes.Select(q => q.Id).ToList());

        var contentProgress =
            await _progressRepository.GetByUserAsync(userId);

        return SkillProgressEngine.Calculate(
            userId,
            skills,
            contentLinks,
            contentProgress,
            quizzes,
            quizAttempts);
    }

    public async Task<List<SkillResponse>> GetBySpecializationAsync(
        Guid specializationId)
    {
        if (!await _skillRepository.SpecializationExistsAsync(specializationId))
            throw new KeyNotFoundException("Uzmanlık bulunamadı.");

        var skills =
            await _skillRepository.GetActiveBySpecializationAsync(specializationId);

        // /api/skills/me ile aynı, collation'dan bağımsız sıralama.
        return skills
            .OrderBy(s => s.Name, StringComparer.Ordinal)
            .ThenBy(s => s.Id)
            .Select(s => new SkillResponse
            {
                Id = s.Id,
                Name = s.Name,
                Description = s.Description,
                Category = s.Category,
            })
            .ToList();
    }
}
