using Menzilim.Application.DTOs.AI;

namespace Menzilim.Application.Interfaces.AI;

/// <summary>
/// AI sağlayıcıları için soyutlama. Somut sağlayıcılar (mock, gerçek LLM vb.)
/// Infrastructure katmanında bu arayüzü uygular.
/// </summary>
public interface IAIProvider
{
    /// <summary>
    /// Sağlayıcının kısa adı (loglama / teşhis amaçlı).
    /// </summary>
    string Name { get; }

    /// <summary>
    /// Verilen isteğe göre bir AI yanıtı üretir.
    /// </summary>
    Task<AICompletionResponse> GenerateAsync(
        AICompletionRequest request,
        CancellationToken cancellationToken = default);
}
