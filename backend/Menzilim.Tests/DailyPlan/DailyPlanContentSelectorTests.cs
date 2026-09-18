using Menzilim.Application.Services.DailyPlan;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.DailyPlan;

public class DailyPlanContentSelectorTests
{
    private static Content MakeContent(
        string title,
        DateTime publishedAt,
        string? description = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Description = description,
            PublishedAt = publishedAt,
            IsActive = true,
        };

    [Fact]
    public void Select_PicksSuitableContent_WhenNoProgress()
    {
        var older = MakeContent("Genel Konu", new DateTime(2026, 1, 1));
        var newer = MakeContent("Yeni Konu", new DateTime(2026, 2, 1));

        var selection = DailyPlanContentSelector.Select(
            new[] { older, newer },
            Array.Empty<UserContentProgress>(),
            specializationName: null);

        // En yeni içerik seçilir (uzmanlık eşleşmesi yoksa yayın tarihine göre).
        Assert.Equal(newer.Id, selection.ContentId);
        Assert.False(selection.IsContinuation);
    }

    [Fact]
    public void Select_PrioritizesSpecializationMatch_OverRecency()
    {
        var newerGeneric = MakeContent("Genel Konu", new DateTime(2026, 3, 1));
        var olderBackend = MakeContent(
            "Backend Temelleri", new DateTime(2026, 1, 1));

        var selection = DailyPlanContentSelector.Select(
            new[] { newerGeneric, olderBackend },
            Array.Empty<UserContentProgress>(),
            specializationName: "Backend");

        Assert.Equal(olderBackend.Id, selection.ContentId);
    }

    [Fact]
    public void Select_PrioritizesInProgressContent_ForContinuation()
    {
        var fresh = MakeContent("Yeni Konu", new DateTime(2026, 3, 1));
        var started = MakeContent("Devam Eden Konu", new DateTime(2026, 1, 1));

        var progress = new[]
        {
            new UserContentProgress
            {
                Id = Guid.NewGuid(),
                ContentId = started.Id,
                StartedAt = new DateTime(2026, 3, 10),
                IsCompleted = false,
            },
        };

        var selection = DailyPlanContentSelector.Select(
            new[] { fresh, started },
            progress,
            specializationName: null);

        Assert.Equal(started.Id, selection.ContentId);
        Assert.True(selection.IsContinuation);
    }

    [Fact]
    public void Select_DoesNotReselectCompletedContent()
    {
        var completed = MakeContent("Bitmiş Konu", new DateTime(2026, 3, 1));
        var available = MakeContent("Açık Konu", new DateTime(2026, 1, 1));

        var progress = new[]
        {
            new UserContentProgress
            {
                Id = Guid.NewGuid(),
                ContentId = completed.Id,
                StartedAt = new DateTime(2026, 2, 1),
                CompletedAt = new DateTime(2026, 2, 2),
                IsCompleted = true,
            },
        };

        var selection = DailyPlanContentSelector.Select(
            new[] { completed, available },
            progress,
            specializationName: null);

        Assert.Equal(available.Id, selection.ContentId);
        Assert.NotEqual(completed.Id, selection.ContentId);
    }

    [Fact]
    public void Select_ReturnsNone_WhenNoContentAvailable()
    {
        var selection = DailyPlanContentSelector.Select(
            Array.Empty<Content>(),
            Array.Empty<UserContentProgress>(),
            specializationName: "Backend");

        Assert.Null(selection.ContentId);
        Assert.False(selection.IsContinuation);
    }

    [Fact]
    public void Select_ReturnsNone_WhenAllContentCompleted()
    {
        var only = MakeContent("Tek Konu", new DateTime(2026, 1, 1));
        var progress = new[]
        {
            new UserContentProgress
            {
                Id = Guid.NewGuid(),
                ContentId = only.Id,
                StartedAt = new DateTime(2026, 1, 2),
                CompletedAt = new DateTime(2026, 1, 3),
                IsCompleted = true,
            },
        };

        var selection = DailyPlanContentSelector.Select(
            new[] { only },
            progress,
            specializationName: null);

        Assert.Null(selection.ContentId);
    }

    [Fact]
    public void Select_IsDeterministic_ForSameInputs()
    {
        var a = MakeContent("A", new DateTime(2026, 1, 1));
        var b = MakeContent("B", new DateTime(2026, 1, 1));

        var first = DailyPlanContentSelector.Select(
            new[] { a, b }, Array.Empty<UserContentProgress>(), null);
        var second = DailyPlanContentSelector.Select(
            new[] { a, b }, Array.Empty<UserContentProgress>(), null);

        Assert.Equal(first.ContentId, second.ContentId);
    }
}
