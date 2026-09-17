using Menzilim.Application.DTOs.Onboarding;

namespace Menzilim.Application.Interfaces.Onboarding;

public interface IOnboardingService
{
    Task<OnboardingResponse> SaveAsync(
        Guid userId,
        OnboardingRequest request);

    Task<OnboardingResponse?> GetAsync(Guid userId);
}
