using Menzilim.Application.Services.DailyPlan;
using Xunit;

namespace Menzilim.Tests.DailyPlan;

public class DailyPlanGeneratorTests
{
    private static DailyPlanGenerationContext Ctx(int minutes) =>
        new()
        {
            ProfessionName = "Yazılım Geliştirici",
            SpecializationName = "Backend",
            ExperienceLevel = "Beginner",
            CareerGoal = "Backend Developer",
            DailyLearningMinutes = minutes,
        };

    [Fact]
    public void ThirtyMinutes_ProducesShortTwoTaskPlan()
    {
        var tasks = DailyPlanGenerator.Generate(Ctx(30));

        Assert.Equal(2, tasks.Count);
        Assert.Equal(new[] { "Learn", "Quiz" }, tasks.Select(t => t.TaskType).ToArray());
        Assert.Equal(18, tasks[0].EstimatedMinutes);
        Assert.Equal(12, tasks[1].EstimatedMinutes);
        Assert.Equal(30, tasks.Sum(t => t.EstimatedMinutes));
    }

    [Fact]
    public void SixtyMinutes_ProducesStandardThreeTaskPlan()
    {
        var tasks = DailyPlanGenerator.Generate(Ctx(60));

        Assert.Equal(3, tasks.Count);
        Assert.Equal(
            new[] { "Learn", "Practice", "Quiz" },
            tasks.Select(t => t.TaskType).ToArray());
        Assert.Equal(25, tasks[0].EstimatedMinutes);
        Assert.Equal(20, tasks[1].EstimatedMinutes);
        Assert.Equal(15, tasks[2].EstimatedMinutes);
        Assert.Equal(60, tasks.Sum(t => t.EstimatedMinutes));
    }

    [Fact]
    public void NinetyMinutes_ProducesComprehensiveFourTaskPlan()
    {
        var tasks = DailyPlanGenerator.Generate(Ctx(90));

        Assert.Equal(4, tasks.Count);
        Assert.Equal(
            new[] { "Learn", "Practice", "Quiz", "Review" },
            tasks.Select(t => t.TaskType).ToArray());
        Assert.Equal(90, tasks.Sum(t => t.EstimatedMinutes));
    }

    [Fact]
    public void ZeroMinutes_FallsBackToSixtyMinuteStandardPlan()
    {
        var tasks = DailyPlanGenerator.Generate(Ctx(0));

        Assert.Equal(3, tasks.Count);
        Assert.Equal(60, tasks.Sum(t => t.EstimatedMinutes));
    }

    [Fact]
    public void Generation_IsDeterministic_ForSameContext()
    {
        var context = Ctx(75);

        var first = DailyPlanGenerator.Generate(context);
        var second = DailyPlanGenerator.Generate(context);

        Assert.Equal(first.Count, second.Count);
        for (var i = 0; i < first.Count; i++)
        {
            Assert.Equal(first[i].TaskType, second[i].TaskType);
            Assert.Equal(first[i].EstimatedMinutes, second[i].EstimatedMinutes);
            Assert.Equal(first[i].Title, second[i].Title);
            Assert.Equal(first[i].Description, second[i].Description);
        }
    }

    [Fact]
    public void TotalMinutes_AlwaysMatchesRequestedTime()
    {
        foreach (var minutes in new[] { 20, 30, 45, 60, 75, 90, 120 })
        {
            var tasks = DailyPlanGenerator.Generate(Ctx(minutes));
            Assert.Equal(minutes, tasks.Sum(t => t.EstimatedMinutes));
        }
    }

    [Fact]
    public void QuizDescription_ReflectsAttemptHistory()
    {
        var firstTime = DailyPlanGenerator.Generate(new DailyPlanGenerationContext
        {
            DailyLearningMinutes = 60,
            QuizAttemptCount = 0,
        });
        var experienced = DailyPlanGenerator.Generate(new DailyPlanGenerationContext
        {
            DailyLearningMinutes = 60,
            QuizAttemptCount = 5,
        });

        var firstQuiz = firstTime.Single(t => t.TaskType == "Quiz");
        var expQuiz = experienced.Single(t => t.TaskType == "Quiz");

        Assert.NotEqual(firstQuiz.Description, expQuiz.Description);
        Assert.Contains("İlk quiz", firstQuiz.Description);
    }
}
