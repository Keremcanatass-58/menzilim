using Menzilim.Application.DTOs.AI;
using Menzilim.Infrastructure.Services.AI;
using Xunit;

namespace Menzilim.Tests.AI;

public class MockAIProviderTests
{
    [Fact]
    public async Task GenerateAsync_WithPrompt_ReturnsMockProviderResponse()
    {
        var provider = new MockAIProvider();

        var response = await provider.GenerateAsync(
            new AICompletionRequest { Prompt = "Merhaba" });

        Assert.Equal("mock", provider.Name);
        Assert.Equal("mock", response.Provider);
        Assert.False(string.IsNullOrWhiteSpace(response.Content));
        Assert.Contains("Merhaba", response.Content);
    }

    [Fact]
    public async Task GenerateAsync_WithEmptyPrompt_ReturnsGreeting()
    {
        var provider = new MockAIProvider();

        var response = await provider.GenerateAsync(
            new AICompletionRequest { Prompt = string.Empty });

        Assert.False(string.IsNullOrWhiteSpace(response.Content));
    }
}
