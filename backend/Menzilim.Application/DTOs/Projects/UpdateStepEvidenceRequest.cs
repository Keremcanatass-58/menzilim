namespace Menzilim.Application.DTOs.Projects;

/// <summary>
/// Adımın çıktısı: çalışmanın bağlantısı ve kısa not. İkisi de opsiyoneldir;
/// boş gönderilirse mevcut kayıt temizlenir.
/// </summary>
public class UpdateStepEvidenceRequest
{
    public string? EvidenceUrl { get; set; }

    public string? Note { get; set; }
}
