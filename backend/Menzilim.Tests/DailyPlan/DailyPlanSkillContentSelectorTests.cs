using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Services.DailyPlan;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.DailyPlan;

public class DailyPlanSkillContentSelectorTests
{
    private static readonly Guid UserId = Guid.NewGuid();

    private static Content MakeContent(string title, int day, string? description = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Description = description,
            PublishedAt = new DateTime(2026, 1, day),
            IsActive = true,
        };

    private static SkillProgressResponse Skill(string name, int progress) =>
        new() { SkillId = Guid.NewGuid(), SkillName = name, Category = "Test", ProgressPercent = progress };

    private static ContentSkill Link(Content content, SkillProgressResponse skill) =>
        new() { Id = Guid.NewGuid(), ContentId = content.Id, SkillId = skill.SkillId };

    private static UserContentProgress Started(Content content, int day = 1) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = UserId,
            ContentId = content.Id,
            StartedAt = new DateTime(2026, 9, day),
        };

    private static UserContentProgress Completed(Content content) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = UserId,
            ContentId = content.Id,
            StartedAt = new DateTime(2026, 9, 1),
            IsCompleted = true,
            CompletedAt = new DateTime(2026, 9, 2),
        };

    private static IReadOnlyList<DailyPlanSkillContentSelector.Selection> Run(
        IReadOnlyList<Content> content,
        IReadOnlyList<ContentSkill> links,
        IReadOnlyList<SkillProgressResponse> skills,
        IReadOnlyList<UserContentProgress>? progress = null,
        int count = 2,
        string? specialization = null) =>
        DailyPlanSkillContentSelector.Select(
            content,
            progress ?? Array.Empty<UserContentProgress>(),
            links,
            skills,
            specialization,
            count);

    [Fact]
    public void ZeroProgressSkillContent_IsSelectedBefore_FiftyPercentSkillContent()
    {
        var aspNet = Skill("ASP.NET Core", 50);
        var csharp = Skill("C#", 0);
        // ASP.NET içeriği daha yeni; yine de %0 skill'in içeriği önce gelmeli.
        var aspContent = MakeContent("ASP.NET Core İleri", day: 20);
        var csharpContent = MakeContent("C# Temelleri", day: 1);

        var result = Run(
            new[] { aspContent, csharpContent },
            new[] { Link(aspContent, aspNet), Link(csharpContent, csharp) },
            new[] { aspNet, csharp });

        Assert.Equal(csharpContent.Id, result[0].ContentId);
        Assert.Equal("C#", result[0].FocusSkillName);
        Assert.Equal(aspContent.Id, result[1].ContentId);
    }

    [Fact]
    public void LowestProgressSkill_HasPriority_AndMultiSkillContentUsesItsLowestSkill()
    {
        var a = Skill("A", 60);
        var b = Skill("B", 20);
        var c = Skill("C", 40);
        var contentB = MakeContent("B içeriği", day: 1);
        var contentC = MakeContent("C içeriği", day: 2);
        // A (%60) ve C (%40)'a bağlı; en düşük bağı %40 → B'den (%20) sonra.
        var contentAC = MakeContent("A+C içeriği", day: 30);

        var result = Run(
            new[] { contentAC, contentC, contentB },
            new[] { Link(contentB, b), Link(contentC, c), Link(contentAC, a), Link(contentAC, c) },
            new[] { a, b, c },
            count: 3);

        Assert.Equal(contentB.Id, result[0].ContentId);
        // C ve A+C aynı öncelikte (%40); grup içinde mevcut kural: daha yeni önce.
        Assert.Equal(contentAC.Id, result[1].ContentId);
        Assert.Equal("C", result[1].FocusSkillName);
        Assert.Equal(contentC.Id, result[2].ContentId);
    }

    [Fact]
    public void CompletedContent_IsNeverSelected_EvenWithDuplicateUnfinishedRecord()
    {
        var sql = Skill("SQL", 0);
        var done = MakeContent("SQL 1", day: 20);
        var open = MakeContent("SQL 2", day: 1);

        var result = Run(
            new[] { done, open },
            new[] { Link(done, sql), Link(open, sql) },
            new[] { sql },
            progress: new[] { Completed(done), Started(done, day: 5) });

        var only = Assert.Single(result);
        Assert.Equal(open.Id, only.ContentId);
        Assert.False(only.IsContinuation);
    }

    [Fact]
    public void InProgressContent_IsPrioritized_OverLowerProgressSkillContent()
    {
        var aspNet = Skill("ASP.NET Core", 50);
        var csharp = Skill("C#", 0);
        var started = MakeContent("ASP.NET Core Devam", day: 1);
        var fresh = MakeContent("C# Temelleri", day: 20);

        var result = Run(
            new[] { fresh, started },
            new[] { Link(started, aspNet), Link(fresh, csharp) },
            new[] { aspNet, csharp },
            progress: new[] { Started(started) });

        Assert.Equal(started.Id, result[0].ContentId);
        Assert.True(result[0].IsContinuation);
        Assert.Equal(fresh.Id, result[1].ContentId);
        Assert.False(result[1].IsContinuation);
    }

    [Fact]
    public void ContentOutsideProfessionScope_IsNeverSelected()
    {
        var csharp = Skill("C#", 0);
        var inScope = MakeContent("Kapsam İçi", day: 1);
        var outOfScope = MakeContent("Kapsam Dışı", day: 20);

        // Kapsam dışı içerik %0 skill'e bağlı olsa da aday listesinde yok.
        var result = Run(
            new[] { inScope },
            new[] { Link(inScope, csharp), Link(outOfScope, csharp) },
            new[] { csharp });

        var only = Assert.Single(result);
        Assert.Equal(inScope.Id, only.ContentId);
    }

    [Fact]
    public void SameContent_IsNeverSelectedTwice()
    {
        var sql = Skill("SQL", 0);
        var content = MakeContent("SQL", day: 1);

        // Aday listesinde aynı içerik iki kez olsa bile tek seçilir.
        var result = Run(
            new[] { content, content },
            new[] { Link(content, sql), Link(content, sql) },
            new[] { sql },
            count: 5);

        Assert.Single(result);
    }

    [Fact]
    public void ManySlots_ReturnDistinctContents()
    {
        var sql = Skill("SQL", 0);
        var items = Enumerable.Range(1, 4).Select(i => MakeContent($"SQL {i}", day: i)).ToList();

        var result = Run(items, items.Select(c => Link(c, sql)).ToList(), new[] { sql }, count: 3);

        Assert.Equal(3, result.Count);
        Assert.Equal(3, result.Select(r => r.ContentId).Distinct().Count());
    }

    [Fact]
    public void NoContent_ReturnsEmpty_SafeFallback()
    {
        var result = Run(Array.Empty<Content>(), Array.Empty<ContentSkill>(), new[] { Skill("C#", 0) });

        Assert.Empty(result);
    }

    [Fact]
    public void AllContentCompleted_ReturnsEmpty()
    {
        var sql = Skill("SQL", 0);
        var content = MakeContent("SQL", day: 1);

        var result = Run(new[] { content }, new[] { Link(content, sql) }, new[] { sql },
            progress: new[] { Completed(content) });

        Assert.Empty(result);
    }

    [Fact]
    public void UnlinkedContent_ComesAfterSkillLinkedContent()
    {
        var git = Skill("Git ve Versiyon Kontrolü", 90);
        var unlinked = MakeContent("Genel Kariyer İpuçları", day: 30);
        var linked = MakeContent("Git Dalları", day: 1);

        var result = Run(new[] { unlinked, linked }, new[] { Link(linked, git) }, new[] { git });

        Assert.Equal(linked.Id, result[0].ContentId);
        Assert.Equal(unlinked.Id, result[1].ContentId);
        Assert.Null(result[1].FocusSkillName);
    }

    [Fact]
    public void WithoutSkillData_FallsBackToExistingSelectorRules()
    {
        // Skill bilgisi yoksa mevcut kural: uzmanlık adı eşleşmesi → yenilik.
        var newerGeneric = MakeContent("Genel Konu", day: 20);
        var olderBackend = MakeContent("Backend Temelleri", day: 1);

        var result = Run(
            new[] { newerGeneric, olderBackend },
            Array.Empty<ContentSkill>(),
            Array.Empty<SkillProgressResponse>(),
            specialization: "Backend");

        Assert.Equal(olderBackend.Id, result[0].ContentId);
        Assert.Equal(newerGeneric.Id, result[1].ContentId);
    }

    [Fact]
    public void SameInput_ProducesSameOrder_RegardlessOfInputOrder()
    {
        var a = Skill("A", 0);
        var b = Skill("B", 0);
        var contents = Enumerable.Range(1, 5).Select(i => MakeContent($"İçerik {i}", day: 10)).ToList();
        var links = contents.Select((c, i) => Link(c, i % 2 == 0 ? a : b)).ToList();

        var first = Run(contents, links, new[] { a, b }, count: 5);
        var second = Run(Enumerable.Reverse(contents).ToList(), Enumerable.Reverse(links).ToList(), new[] { b, a }, count: 5);

        Assert.Equal(first.Select(r => r.ContentId), second.Select(r => r.ContentId));
    }
}
