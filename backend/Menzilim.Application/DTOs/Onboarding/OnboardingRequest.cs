namespace Menzilim.Application.DTOs.Onboarding;

public class OnboardingRequest
{
    public Guid ProfessionId { get; set; }
    public Guid SpecializationId { get; set; }
    public string ExperienceLevel { get; set; } = string.Empty;
    public string CareerGoal { get; set; } = string.Empty;
    public int DailyLearningMinutes { get; set; }
}
