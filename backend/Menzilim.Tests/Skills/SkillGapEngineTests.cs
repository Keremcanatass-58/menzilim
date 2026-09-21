using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Services.Skills;
using Menzilim.Domain;
using Xunit;

namespace Menzilim.Tests.Skills;

/// <summary>
/// Beceri açığı hesabı: mevcut seviye, hedef seviye ve durum.
/// </summary>
public class SkillGapEngineTests
{
    private static SkillProgressResponse Progress(
        string name,
        int percent,
        Guid? id = null) =>
        new()
        {
            SkillId = id ?? Guid.NewGuid(),
            SkillName = name,
            Category = "Web",
            ProgressPercent = percent,
        };

    [Theory]
    [InlineData(0, SkillLevels.None)]
    [InlineData(1, SkillLevels.Beginner)]
    [InlineData(39, SkillLevels.Beginner)]
    [InlineData(40, SkillLevels.Intermediate)]
    [InlineData(79, SkillLevels.Intermediate)]
    [InlineData(80, SkillLevels.Advanced)]
    [InlineData(100, SkillLevels.Advanced)]
    public void CurrentLevel_FollowsProgressThresholds(int percent, string expected)
    {
        var skill = Progress("SQL", percent);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { skill },
            new Dictionary<Guid, string> { [skill.SkillId] = SkillLevels.Advanced });

        Assert.Equal(expected, result.Items.Single().CurrentLevel);
    }

    [Fact]
    public void Status_IsReached_WhenCurrentLevelMeetsTarget()
    {
        var skill = Progress("C#", 45);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { skill },
            new Dictionary<Guid, string> { [skill.SkillId] = SkillLevels.Intermediate });

        var item = result.Items.Single();

        Assert.Equal(SkillGapEngine.Reached, item.Status);
        Assert.Equal(SkillLevels.Intermediate, item.CurrentLevel);
        Assert.Equal(SkillLevels.Intermediate, item.TargetLevel);
        Assert.Equal(40, item.TargetProgressPercent);
        Assert.Equal(1, result.ReachedCount);
        Assert.Equal(0, result.RemainingCount);
    }

    [Fact]
    public void Status_IsNotStarted_WhenNoProgress()
    {
        var skill = Progress("REST API", 0);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { skill },
            new Dictionary<Guid, string> { [skill.SkillId] = SkillLevels.Intermediate });

        var item = result.Items.Single();

        Assert.Equal(SkillGapEngine.NotStarted, item.Status);
        Assert.Equal(SkillLevels.None, item.CurrentLevel);
        Assert.Equal(1, result.NotStartedCount);
        Assert.Equal(1, result.RemainingCount);
    }

    [Fact]
    public void Status_SeparatesDevelopingFromNeedsWork()
    {
        // Hedef Intermediate (eşik 40): yarısı ve üzeri "gelişiyor".
        var developing = Progress("SQL", 25);
        var needsWork = Progress("Entity Framework Core", 10);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { developing, needsWork },
            new Dictionary<Guid, string>
            {
                [developing.SkillId] = SkillLevels.Intermediate,
                [needsWork.SkillId] = SkillLevels.Intermediate,
            });

        Assert.Equal(
            SkillGapEngine.Developing,
            result.Items.Single(i => i.SkillName == "SQL").Status);

        Assert.Equal(
            SkillGapEngine.NeedsWork,
            result.Items.Single(i => i.SkillName == "Entity Framework Core").Status);

        // İkisi de "geliştiriliyor" sayılır (özet için).
        Assert.Equal(2, result.DevelopingCount);
        Assert.Equal(2, result.RemainingCount);
    }

    [Fact]
    public void Items_AreOrderedByClosestToTarget()
    {
        var notStarted = Progress("Authentication", 0);
        var needsWork = Progress("SQL", 10);
        var developing = Progress("REST API", 30);
        var reached = Progress("C#", 90);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { notStarted, reached, needsWork, developing },
            new Dictionary<Guid, string>
            {
                [notStarted.SkillId] = SkillLevels.Intermediate,
                [needsWork.SkillId] = SkillLevels.Intermediate,
                [developing.SkillId] = SkillLevels.Intermediate,
                [reached.SkillId] = SkillLevels.Intermediate,
            });

        Assert.Equal(
            new[] { "REST API", "SQL", "Authentication", "C#" },
            result.Items.Select(i => i.SkillName));
    }

    [Fact]
    public void MissingTarget_FallsBackToIntermediate()
    {
        var skill = Progress("Git ve Versiyon Kontrolü", 0);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { skill },
            new Dictionary<Guid, string>());

        Assert.Equal(SkillLevels.Intermediate, result.Items.Single().TargetLevel);
    }

    [Fact]
    public void Summary_CountsAllBuckets()
    {
        var reached = Progress("C#", 100);
        var developing = Progress("SQL", 30);
        var notStarted = Progress("REST API", 0);

        var result = SkillGapEngine.Calculate(
            "Backend",
            new[] { reached, developing, notStarted },
            new Dictionary<Guid, string>
            {
                [reached.SkillId] = SkillLevels.Intermediate,
                [developing.SkillId] = SkillLevels.Intermediate,
                [notStarted.SkillId] = SkillLevels.Intermediate,
            });

        Assert.Equal("Backend", result.SpecializationName);
        Assert.Equal(3, result.TotalCount);
        Assert.Equal(1, result.ReachedCount);
        Assert.Equal(1, result.DevelopingCount);
        Assert.Equal(1, result.NotStartedCount);
        Assert.Equal(2, result.RemainingCount);
    }
}
