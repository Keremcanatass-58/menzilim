using Menzilim.Application.DTOs.AI;
using Menzilim.Application.Interfaces.AI;

namespace Menzilim.Infrastructure.Services.AI;

/// <summary>
/// Gerçek bir AI servisine bağlanmayan, geliştirme/test amaçlı sahte sağlayıcı.
/// Dış çağrı yapmaz ve API anahtarı gerektirmez.
/// </summary>
public class MockAIProvider : IAIProvider
{
    public string Name => "mock";

    public Task<AICompletionResponse> GenerateAsync(
        AICompletionRequest request,
        CancellationToken cancellationToken = default)
    {
        var prompt = request.Prompt?.Trim() ?? string.Empty;

        var content = string.IsNullOrEmpty(prompt)
            ? "Merhaba! Ben Menzilim AI koçuyum. Sana nasıl yardımcı olabilirim?"
            : $"(Mock yanıt) Sorunu aldım: \"{prompt}\". Gerçek AI sağlayıcısı henüz bağlı değil.";

        var response = new AICompletionResponse
        {
            Content = content,
            Provider = Name,
            CreatedAt = DateTime.UtcNow
        };

        return Task.FromResult(response);
    }
}
