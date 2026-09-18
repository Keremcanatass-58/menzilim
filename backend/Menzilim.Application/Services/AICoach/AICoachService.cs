using Menzilim.Application.DTOs.AI;
using Menzilim.Application.DTOs.AICoach;
using Menzilim.Application.Interfaces.AI;
using Menzilim.Application.Interfaces.AICoach;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;

namespace Menzilim.Application.Services.AICoach;

public class AICoachService : IAICoachService
{
    private readonly IUserRepository _userRepository;
    private readonly IAIProvider _aiProvider;

    public AICoachService(
        IUserRepository userRepository,
        IAIProvider aiProvider)
    {
        _userRepository = userRepository;
        _aiProvider = aiProvider;
    }

    public async Task<AICoachAnswerResponse> AskAsync(
        Guid userId,
        AICoachAskRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Prompt))
        {
            throw new InvalidOperationException("Soru boş olamaz.");
        }

        var user = await _userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (user?.Profile is null)
        {
            throw new KeyNotFoundException("Kullanıcı profili bulunamadı.");
        }

        var systemPrompt = BuildSystemPrompt(user);

        var completion = await _aiProvider.GenerateAsync(
            new AICompletionRequest
            {
                Prompt = request.Prompt.Trim(),
                SystemPrompt = systemPrompt
            },
            cancellationToken);

        return new AICoachAnswerResponse
        {
            Answer = completion.Content,
            Provider = completion.Provider,
            CreatedAt = completion.CreatedAt
        };
    }

    private static string BuildSystemPrompt(User user)
    {
        // AskAsync içinde Profile null kontrolü yapıldı; burada garanti edilir.
        var profile = user.Profile!;

        return
            "Sen Menzilim uygulamasının kişisel kariyer ve öğrenme koçusun. " +
            "Kullanıcıya Türkçe, motive edici, kısa ve uygulanabilir tavsiyeler ver. " +
            "Kullanıcının profili:\n" +
            $"- Ad: {user.FirstName} {user.LastName}\n" +
            $"- Meslek: {profile.Profession.Name}\n" +
            $"- Uzmanlık: {profile.Specialization.Name}\n" +
            $"- Deneyim seviyesi: {profile.ExperienceLevel}\n" +
            $"- Kariyer hedefi: {profile.CareerGoal}\n" +
            "Yanıtlarını bu profile göre kişiselleştir.";
    }
}
