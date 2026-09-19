using Menzilim.Application.DTOs.Skills;

namespace Menzilim.Application.Interfaces.Skills;

public interface ISkillService
{
    Task<List<SkillProgressResponse>> GetMyProgressAsync(Guid userId);

    Task<List<SkillResponse>> GetBySpecializationAsync(Guid specializationId);
}
