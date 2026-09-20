using Menzilim.Domain;

namespace Menzilim.Application.Interfaces.Repositories;

public interface IUserProjectRepository
{
    /// <summary>Kullanıcının projeleri (adımlar, içerik ve beceri dahil).</summary>
    Task<List<UserProject>> GetByUserAsync(Guid userId);

    Task<UserProject?> GetByIdAsync(Guid projectId);

    /// <summary>Adımı, sahibi olan proje ve diğer adımlarıyla birlikte getirir.</summary>
    Task<UserProjectStep?> GetStepWithProjectAsync(Guid stepId);

    /// <summary>Uzmanlığa bağlı aktif proje şablonu (adımlarıyla).</summary>
    Task<LearningPath?> GetTemplateBySpecializationAsync(Guid specializationId);

    Task AddAsync(UserProject project);

    Task SaveChangesAsync();
}
