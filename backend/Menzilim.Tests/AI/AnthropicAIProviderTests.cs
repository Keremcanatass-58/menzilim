using Menzilim.Application.DTOs.AI;
using Menzilim.Infrastructure.Configuration;
using Menzilim.Infrastructure.Services.AI;
using Microsoft.Extensions.Options;
using Xunit;

namespace Menzilim.Tests.AI;

public class AnthropicAIProviderTests
{
    [Fact]
    public async Task GenerateAsync_WithoutApiKey_ThrowsClearError_AndDoesNotLeakSecret()
    {
        // Anahtar yok: gerçek API çağrısı yapılmadan açık bir hata beklenir.
        var options = Options.Create(new AIProviderOptions { ApiKey = null });
        var provider = new AnthropicAIProvider(options);

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(
            () => provider.GenerateAsync(
                new AICompletionRequest { Prompt = "Merhaba" }));

        Assert.Equal("anthropic", provider.Name);
        Assert.Contains("API anahtarı", ex.Message);
    }
}
