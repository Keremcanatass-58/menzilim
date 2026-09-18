using Anthropic;
using Anthropic.Models.Messages;
using Menzilim.Application.DTOs.AI;
using Menzilim.Application.Interfaces.AI;
using Menzilim.Infrastructure.Configuration;
using Microsoft.Extensions.Options;

namespace Menzilim.Infrastructure.Services.AI;

/// <summary>
/// Anthropic Claude Messages API üzerinden çalışan gerçek AI sağlayıcısı.
/// API anahtarı yalnızca çağrı anında doğrulanır; bu sayede anahtar
/// yapılandırılmamışsa uygulama başlangıçta çökmek yerine çağrı sırasında
/// açık bir hata döndürür.
/// </summary>
public class AnthropicAIProvider : IAIProvider
{
    private readonly AIProviderOptions _options;

    public AnthropicAIProvider(IOptions<AIProviderOptions> options)
    {
        _options = options.Value;
    }

    public string Name => "anthropic";

    public async Task<AICompletionResponse> GenerateAsync(
        AICompletionRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            // Mesaj gizli bilgi içermez; yalnızca eksik yapılandırmayı bildirir.
            throw new InvalidOperationException(
                "AI sağlayıcısı için API anahtarı yapılandırılmamış. " +
                "ANTHROPIC_API_KEY ortam değişkenini veya User Secrets'ı ayarlayın.");
        }

        var client = new AnthropicClient { ApiKey = _options.ApiKey };

        var parameters = new MessageCreateParams
        {
            Model = _options.Model,
            MaxTokens = _options.MaxTokens,
            System = request.SystemPrompt ?? string.Empty,
            Messages = [new() { Role = Role.User, Content = request.Prompt }],
        };

        var response = await client.Messages.Create(parameters);

        var content = string.Join(
            "\n",
            response.Content
                .Select(block => block.Value)
                .OfType<TextBlock>()
                .Select(text => text.Text));

        return new AICompletionResponse
        {
            Content = content,
            Provider = Name,
            CreatedAt = DateTime.UtcNow,
        };
    }
}
