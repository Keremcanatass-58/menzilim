using Menzilim.Application.Services.DailyPlan;
using Xunit;
using DomainQuiz = Menzilim.Domain.Quiz;

namespace Menzilim.Tests.DailyPlan;

public class DailyPlanQuizSelectorTests
{
    private static readonly DateTime T0 = new(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc);

    private static DomainQuiz Quiz(
        string title,
        string? description = null,
        int minutesAfterT0 = 0,
        bool isActive = true) =>
        new()
        {
            Id = Guid.NewGuid(),
            Title = title,
            Description = description,
            CreatedAt = T0.AddMinutes(minutesAfterT0),
            IsActive = isActive,
        };

    [Fact]
    public void Select_PrefersQuizNamingTheSpecialization_OverOlderSharedSkillQuiz()
    {
        // Backend skill'leri ASP.NET, REST ve EF Core quiz'lerinin hepsine bağlı.
        var aspNet = Quiz("ASP.NET Core Temelleri", "ASP.NET Core mimarisi.", 0);
        var rest = Quiz("REST API Temelleri", "Full Stack: HTTP metotları.", 1);
        var efCore = Quiz("Entity Framework Core ve SQL Temelleri", "Backend: EF Core ve SQL.", 2);

        var selected = DailyPlanQuizSelector.Select(new[] { aspNet, rest, efCore }, "Backend");

        Assert.Same(efCore, selected);
    }

    [Fact]
    public void Select_MatchesSpecializationName_InTitle_CaseInsensitively()
    {
        var generic = Quiz("Genel Quiz", null, 0);
        var mobile = Quiz("mobile hazırlık", null, 5);

        Assert.Same(mobile, DailyPlanQuizSelector.Select(new[] { generic, mobile }, "Mobile"));
    }

    [Fact]
    public void Select_WithoutNameMatch_TakesOldestSkillLinkedQuiz()
    {
        var newer = Quiz("B", null, 10);
        var older = Quiz("A", null, 1);

        Assert.Same(older, DailyPlanQuizSelector.Select(new[] { newer, older }, "SOC"));
    }

    [Fact]
    public void Select_IgnoresInactiveQuizzes()
    {
        var inactiveMatch = Quiz("Frontend Quiz", "Frontend", 0, isActive: false);
        var active = Quiz("JavaScript", null, 1);

        Assert.Same(active, DailyPlanQuizSelector.Select(new[] { inactiveMatch, active }, "Frontend"));
    }

    [Fact]
    public void Select_WithNoCandidates_ReturnsNull_SoCallerFallsBack()
    {
        Assert.Null(DailyPlanQuizSelector.Select(Array.Empty<DomainQuiz>(), "Backend"));
    }

    [Fact]
    public void Select_IsDeterministic_ForEqualCandidates()
    {
        var a = Quiz("Frontend A", null, 0);
        var b = Quiz("Frontend B", null, 0);
        var expected = a.Id.CompareTo(b.Id) < 0 ? a : b;

        Assert.Same(expected, DailyPlanQuizSelector.Select(new[] { a, b }, "Frontend"));
        Assert.Same(expected, DailyPlanQuizSelector.Select(new[] { b, a }, "Frontend"));
    }
}
