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

    /// <summary>
    /// Adımın çıktısını (bağlantı ve not) günceller. Adım kullanıcıya ait
    /// değilse null; bağlantı geçersizse InvalidOperationException.
    /// Tamamlama koşulu değildir: her durumda eklenebilir.
    /// </summary>
    Task<UserProjectResponse?> UpdateStepEvidenceAsync(
        Guid userId,
        Guid stepId,
        UpdateStepEvidenceRequest request);
}
