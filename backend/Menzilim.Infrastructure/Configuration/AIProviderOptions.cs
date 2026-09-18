namespace Menzilim.Infrastructure.Configuration;

/// <summary>
/// AI sağlayıcısı yapılandırması. Gizli olmayan alanlar appsettings/ortamdan
/// bağlanır; API anahtarı yalnızca User Secrets veya ortam değişkeni ile sağlanır.
/// </summary>
public class AIProviderOptions
{
    public const string SectionName = "AIProvider";

    /// <summary>
    /// Kullanılacak sağlayıcı: "mock" (varsayılan) veya "anthropic".
    /// </summary>
    public string Provider { get; set; } = "mock";

    /// <summary>
    /// Kullanılacak model kimliği.
    /// </summary>
    public string Model { get; set; } = "claude-opus-4-8";

    /// <summary>
    /// Üretilecek maksimum çıktı token sayısı.
    /// </summary>
    public int MaxTokens { get; set; } = 1024;

    /// <summary>
    /// API anahtarı. Koda veya appsettings.json'a YAZILMAZ; ortam değişkeni
    /// (AIProvider__ApiKey veya ANTHROPIC_API_KEY) ya da User Secrets ile sağlanır.
    /// </summary>
    public string? ApiKey { get; set; }
}
