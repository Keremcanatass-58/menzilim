using Menzilim.Application.Services.Content;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.ContentRecommendation;

public class ContentRecommendationEngineTests
{
    private static Menzilim.Domain.Content MakeContent(
        string title,
        DateTime publishedAt,
        string level = "",
        string? description = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Description = description,
            Url = $"https://example.com/{Guid.NewGuid()}",
            PublishedAt = publishedAt,
            Level = level,
            IsActive = true,
        };

    private static UserContentProgress Progress(
        Menzilim.Domain.Content content,
        bool completed) =>
        new()
        {
            Id = Guid.NewGuid(),
            ContentId = content.Id,
            StartedAt = new DateTime(2026, 9, 1),
            IsCompleted = completed,
            CompletedAt = completed ? new DateTime(2026, 9, 2) : null,
        };

    private static List<Menzilim.Application.DTOs.Content.ContentRecommendationResponse> Run(
        IReadOnlyList<Menzilim.Domain.Content> professionContent,
        IReadOnlyList<UserContentProgress> progress,
        IReadOnlyList<Menzilim.Domain.Content>? allActive = null,
        string? specialization = "Backend",
        string? level = null,
        string? careerGoal = null) =>
        ContentRecommendationEngine.Recommend(
            professionContent,
            allActive ?? professionContent,
            progress,
            "Yazılım Geliştirici",
            specialization,
            level,
            careerGoal);

    [Fact]
    public void Recommend_ReturnsAtMostFive()
    {
        var content = Enumerable.Range(1, 8)
            .Select(i => MakeContent($"Konu {i}", new DateTime(2026, 1, i)))
            .ToList();

        var result = Run(content, Array.Empty<UserContentProgress>());

        Assert.Equal(5, result.Count);
    }

    [Fact]
    public void Recommend_ClampsRequestedCountToFive()
    {
        var content = Enumerable.Range(1, 8)
            .Select(i => MakeContent($"Konu {i}", new DateTime(2026, 1, i)))
            .ToList();

        var result = ContentRecommendationEngine.Recommend(
            content, content, Array.Empty<UserContentProgress>(),
            null, null, null, null, count: 20);

        Assert.Equal(5, result.Count);
    }

    [Fact]
    public void Recommend_ExcludesCompletedContent()
    {
        var done = MakeContent("Bitmiş Konu", new DateTime(2026, 3, 1));
        var open = MakeContent("Açık Konu", new DateTime(2026, 1, 1));

        var result = Run(new[] { done, open }, new[] { Progress(done, completed: true) });

        Assert.Single(result);
        Assert.Equal(open.Id, result[0].ContentId);
        Assert.All(result, r => Assert.False(r.IsCompleted));
    }

    [Fact]
    public void Recommend_PrioritizesInProgress_OverSpecializationMatch()
    {
        var backend = MakeContent("Backend Temelleri", new DateTime(2026, 3, 1));
        var started = MakeContent("Git Temelleri", new DateTime(2026, 1, 1));

        var result = Run(new[] { backend, started }, new[] { Progress(started, completed: false) });

        Assert.Equal(started.Id, result[0].ContentId);
        Assert.True(result[0].IsStarted);
        Assert.Contains("kaldığın yerden devam", result[0].RecommendationReason);
        Assert.Equal(backend.Id, result[1].ContentId);
    }

    [Fact]
    public void Recommend_PrioritizesSpecialization_OverProfessionFallback()
    {
        var newerGeneric = MakeContent("Genel Konu", new DateTime(2026, 3, 1));
        var olderBackend = MakeContent(
            "API Tasarımı", new DateTime(2026, 1, 1), description: "Backend servisleri için.");

        var result = Run(new[] { newerGeneric, olderBackend }, Array.Empty<UserContentProgress>());

        Assert.Equal(olderBackend.Id, result[0].ContentId);
        Assert.Equal("Uzmanlığın Backend olduğu için öneriliyor.", result[0].RecommendationReason);
        Assert.Equal(newerGeneric.Id, result[1].ContentId);
        Assert.StartsWith(
            "Mesleğin Yazılım Geliştirici ile ilgili olduğu için öneriliyor.",
            result[1].RecommendationReason);
    }

    [Fact]
    public void Recommend_DoesNotSuggestOtherProfessionContent_UnlessStarted()
    {
        var own = MakeContent("Kendi Konum", new DateTime(2026, 1, 1));
        var otherNotStarted = MakeContent("Başka Meslek", new DateTime(2026, 3, 1));
        var otherStarted = MakeContent("Başka Meslek Devam", new DateTime(2026, 2, 1));

        var result = Run(
            new[] { own },
            new[] { Progress(otherStarted, completed: false) },
            allActive: new[] { own, otherNotStarted, otherStarted });

        Assert.Equal(2, result.Count);
        Assert.Equal(otherStarted.Id, result[0].ContentId);
        Assert.Equal(own.Id, result[1].ContentId);
        Assert.DoesNotContain(result, r => r.ContentId == otherNotStarted.Id);
    }

    [Fact]
    public void Recommend_PrefersMatchingExperienceLevel_WithinSameTier()
    {
        var advanced = MakeContent("İleri Konu", new DateTime(2026, 3, 1), level: "Advanced");
        var junior = MakeContent("Giriş Konusu", new DateTime(2026, 1, 1), level: "Junior");

        var result = Run(
            new[] { advanced, junior },
            Array.Empty<UserContentProgress>(),
            level: "junior",
            careerGoal: "Senior olmak");

        Assert.Equal(junior.Id, result[0].ContentId);
        Assert.Equal(
            "Mesleğin Yazılım Geliştirici ile ilgili olduğu için öneriliyor. junior seviyene uygun. Kariyer hedefin (Senior olmak) doğrultusunda faydalı olabilir.",
            result[0].RecommendationReason);
    }

    [Fact]
    public void Recommend_OrdersAllFourTiers()
    {
        // Yayın tarihleri beklenen sıranın tersine verildi; sırayı tier belirlemeli.
        var profession = MakeContent("Genel Konu", new DateTime(2026, 4, 1));
        var specOnly = MakeContent("Backend Mimarisi", new DateTime(2026, 3, 1));
        var startedOnly = MakeContent("Git Temelleri", new DateTime(2026, 2, 1));
        var startedSpec = MakeContent("Backend Güvenliği", new DateTime(2026, 1, 1));

        var result = Run(
            new[] { profession, specOnly, startedOnly, startedSpec },
            new[] { Progress(startedOnly, completed: false), Progress(startedSpec, completed: false) });

        Assert.Equal(
            new[] { startedSpec.Id, startedOnly.Id, specOnly.Id, profession.Id },
            result.Select(r => r.ContentId));
        Assert.Equal(
            "Uzmanlığın Backend ile ilgili bu içeriğe başlamışsın, kaldığın yerden devam edebilirsin.",
            result[0].RecommendationReason);
    }

    [Fact]
    public void Recommend_ExcludesContent_WhenAnyProgressRowIsCompleted()
    {
        var content = MakeContent("Backend Konu", new DateTime(2026, 1, 1));

        var result = Run(
            new[] { content },
            new[] { Progress(content, completed: false), Progress(content, completed: true) },
            allActive: new[] { content });

        Assert.Empty(result);
    }

    [Fact]
    public void Recommend_ExcludesCompletedOtherProfessionContent()
    {
        var own = MakeContent("Kendi Konum", new DateTime(2026, 1, 1));
        var otherCompleted = MakeContent("Başka Meslek", new DateTime(2026, 3, 1));

        var result = Run(
            new[] { own },
            new[] { Progress(otherCompleted, completed: true) },
            allActive: new[] { own, otherCompleted });

        Assert.Single(result);
        Assert.Equal(own.Id, result[0].ContentId);
    }

    [Fact]
    public void Recommend_ReturnsEmpty_WhenEverythingCompleted()
    {
        var a = MakeContent("A", new DateTime(2026, 1, 1));

        var result = Run(new[] { a }, new[] { Progress(a, completed: true) });

        Assert.Empty(result);
    }
}
