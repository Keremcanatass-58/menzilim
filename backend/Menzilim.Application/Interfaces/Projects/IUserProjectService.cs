using Menzilim.Application.DTOs.Projects;

namespace Menzilim.Application.Interfaces.Projects;

public interface IUserProjectService
{
    /// <summary>
    /// Kullanıcının projeleri. Uzmanlığına bağlı şablon varsa ve proje henüz
    /// yoksa proje ilk çağrıda oluşturulur.
    /// </summary>
    Task<List<UserProjectResponse>> GetMyProjectsAsync(Guid userId);

    /// <summary>Kullanıcıya ait değilse null döner.</summary>
    Task<UserProjectResponse?> GetByIdAsync(Guid userId, Guid projectId);

    /// <summary>
    /// Adımı tamamlar ve sonrakini açar. Adım kullanıcıya ait değilse null,
    /// tamamlanabilir durumda değilse InvalidOperationException.
    /// </summary>
    Task<UserProjectResponse?> CompleteStepAsync(Guid userId, Guid stepId);
}
