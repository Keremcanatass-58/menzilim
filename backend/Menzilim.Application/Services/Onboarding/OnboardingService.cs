using Menzilim.Application.DTOs.Onboarding;
using Menzilim.Application.Interfaces.Onboarding;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Domain;

namespace Menzilim.Application.Services.Onboarding;

public class OnboardingService : IOnboardingService
{
    private readonly IUserRepository _userRepository;

    public OnboardingService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<OnboardingResponse> SaveAsync(
        Guid userId,
        OnboardingRequest request)
    {
        var user = await _userRepository.GetByIdAsync(userId);

        if (user is null)
            throw new InvalidOperationException("Kullanıcı bulunamadı.");

        var profile = user.Profile;

        if (profile is null)
        {
            profile = new UserProfile
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ProfessionId = request.ProfessionId,
                SpecializationId = request.SpecializationId,
                ExperienceLevel = request.ExperienceLevel.Trim(),
                CareerGoal = request.CareerGoal.Trim(),
                DailyLearningMinutes = request.DailyLearningMinutes,
                UpdatedAt = DateTime.UtcNow
            };

            await _userRepository.AddProfileAsync(profile);
        }
        else
        {
            profile.ProfessionId = request.ProfessionId;
            profile.SpecializationId = request.SpecializationId;
            profile.ExperienceLevel = request.ExperienceLevel.Trim();
            profile.CareerGoal = request.CareerGoal.Trim();
            profile.DailyLearningMinutes = request.DailyLearningMinutes;
            profile.UpdatedAt = DateTime.UtcNow;
        }

        await _userRepository.SaveChangesAsync();

        return new OnboardingResponse
        {
            UserId = userId,
            ProfessionId = profile.ProfessionId,
            SpecializationId = profile.SpecializationId,
            ExperienceLevel = profile.ExperienceLevel,
            CareerGoal = profile.CareerGoal,
            DailyLearningMinutes = profile.DailyLearningMinutes
        };
    }

    public async Task<OnboardingResponse?> GetAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);

        if (user?.Profile is null)
            return null;

        var profile = user.Profile;

        return new OnboardingResponse
        {
            UserId = userId,
            ProfessionId = profile.ProfessionId,
            SpecializationId = profile.SpecializationId,
            ExperienceLevel = profile.ExperienceLevel,
            CareerGoal = profile.CareerGoal,
            DailyLearningMinutes = profile.DailyLearningMinutes
        };
    }
}
