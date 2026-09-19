using Menzilim.Application.DTOs.Skills;
using Menzilim.Application.Services.Skills;
using Menzilim.Domain;
using Xunit;
using DomainQuiz = Menzilim.Domain.Quiz;

namespace Menzilim.Tests.Skills;

public class SkillProgressEngineTests
{
    private static readonly Guid UserId = Guid.NewGuid();

    private static Skill MakeSkill(string name) =>
        new() { Id = Guid.NewGuid(), Name = name, Category = "Test", IsActive = true };

    private static ContentSkill Link(Guid contentId, Skill skill) =>
        new() { Id = Guid.NewGuid(), ContentId = contentId, SkillId = skill.Id };

    private static UserContentProgress Started(Guid contentId, Guid? userId = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId ?? UserId,
            ContentId = contentId,
            StartedAt = new DateTime(2026, 9, 1),
        };

    private static UserContentProgress Completed(Guid contentId, Guid? userId = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            UserId = userId ?? UserId,
            ContentId = contentId,
            StartedAt = new DateTime(2026, 9, 1),
            IsCompleted = true,
            CompletedAt = new DateTime(2026, 9, 2),
        };

    private static DomainQuiz MakeQuiz(Skill? skill) =>
        new() { Id = Guid.NewGuid(), Title = "Quiz", SkillId = skill?.Id, IsActive = true };

    private static QuizAttempt Attempt(
        DomainQuiz quiz,
        int score,
        int day = 1,
        Guid? userId = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            QuizId = quiz.Id,
            UserId = userId ?? UserId,
            Score = score,
            CompletedAt = new DateTime(2026, 9, day),
        };

    private static SkillProgressResponse Single(
        Skill skill,
        IReadOnlyList<ContentSkill>? links = null,
        IReadOnlyList<UserContentProgress>? progress = null,
        IReadOnlyList<DomainQuiz>? quizzes = null,
        IReadOnlyList<QuizAttempt>? attempts = null)
    {
        var result = SkillProgressEngine.Calculate(
            UserId,
            new[] { skill },
            links ?? Array.Empty<ContentSkill>(),
            progress ?? Array.Empty<UserContentProgress>(),
            quizzes ?? Array.Empty<DomainQuiz>(),
            attempts ?? Array.Empty<QuizAttempt>());

        return Assert.Single(result);
    }

    [Fact]
    public void NoActivity_ReturnsZero()
    {
        var skill = MakeSkill("ASP.NET Core");
        var contentId = Guid.NewGuid();
        var quiz = MakeQuiz(skill);

        var result = Single(skill, links: new[] { Link(contentId, skill) }, quizzes: new[] { quiz });

        Assert.Equal(0, result.ProgressPercent);
        Assert.Equal(1, result.TotalContentCount);
        Assert.Equal(0, result.CompletedContentCount);
        Assert.Equal(0, result.InProgressContentCount);
        Assert.Equal(1, result.TotalQuizCount);
        Assert.Equal(0, result.QuizAttemptCount);
        Assert.Null(result.BestQuizScore);
        Assert.Null(result.LatestQuizScore);
    }

    [Fact]
    public void NoLearningMaterial_ReturnsZero()
    {
        var result = Single(MakeSkill("Linux"));

        Assert.Equal(0, result.ProgressPercent);
        Assert.Equal(0, result.TotalContentCount);
        Assert.Equal(0, result.TotalQuizCount);
    }

    [Fact]
    public void OnlyCompletedContent_UsesCompletionRatio()
    {
        var skill = MakeSkill("SQL");
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();
        var c3 = Guid.NewGuid();

        var result = Single(
            skill,
            links: new[] { Link(c1, skill), Link(c2, skill), Link(c3, skill) },
            progress: new[] { Completed(c1) });

        // 1/3 × 100 = 33.33 → 33
        Assert.Equal(33, result.ProgressPercent);
        Assert.Equal(1, result.CompletedContentCount);
        Assert.Equal(3, result.TotalContentCount);
    }

    [Fact]
    public void OnlyInProgressContent_IsCountedButDoesNotAddProgress()
    {
        var skill = MakeSkill("SQL");
        var c1 = Guid.NewGuid();

        var result = Single(skill, links: new[] { Link(c1, skill) }, progress: new[] { Started(c1) });

        Assert.Equal(0, result.ProgressPercent);
        Assert.Equal(1, result.InProgressContentCount);
        Assert.Equal(0, result.CompletedContentCount);
    }

    [Fact]
    public void CompletedAtWithoutIsCompletedFlag_IsTreatedAsCompleted()
    {
        var skill = MakeSkill("SQL");
        var c1 = Guid.NewGuid();
        var progress = Started(c1);
        progress.CompletedAt = new DateTime(2026, 9, 3);

        var result = Single(skill, links: new[] { Link(c1, skill) }, progress: new[] { progress });

        Assert.Equal(100, result.ProgressPercent);
        Assert.Equal(1, result.CompletedContentCount);
        Assert.Equal(0, result.InProgressContentCount);
    }

    [Fact]
    public void OnlyQuiz_UsesScore()
    {
        var skill = MakeSkill("ASP.NET Core");
        var quiz = MakeQuiz(skill);

        var result = Single(skill, quizzes: new[] { quiz }, attempts: new[] { Attempt(quiz, 67) });

        Assert.Equal(67, result.ProgressPercent);
        Assert.Equal(1, result.QuizAttemptCount);
        Assert.Equal(67, result.BestQuizScore);
        Assert.Equal(67, result.LatestQuizScore);
    }

    [Fact]
    public void UnattemptedQuiz_CountsAsZero_InQuizAverage()
    {
        var skill = MakeSkill("ASP.NET Core");
        var q1 = MakeQuiz(skill);
        var q2 = MakeQuiz(skill);

        var result = Single(skill, quizzes: new[] { q1, q2 }, attempts: new[] { Attempt(q1, 80) });

        // (80 + 0) / 2 = 40
        Assert.Equal(40, result.ProgressPercent);
        Assert.Equal(2, result.TotalQuizCount);
        Assert.Equal(1, result.AttemptedQuizCount);
    }

    [Fact]
    public void ContentAndQuiz_AreAveragedEqually()
    {
        var skill = MakeSkill("ASP.NET Core");
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            links: new[] { Link(c1, skill), Link(c2, skill) },
            progress: new[] { Completed(c1) },
            quizzes: new[] { quiz },
            attempts: new[] { Attempt(quiz, 100) });

        // İçerik %50, quiz %100 → (50 + 100) / 2 = 75
        Assert.Equal(75, result.ProgressPercent);
    }

    [Fact]
    public void MultipleContents_ForSameSkill_AreAllCounted()
    {
        var skill = MakeSkill("C#");
        var ids = Enumerable.Range(0, 4).Select(_ => Guid.NewGuid()).ToList();

        var result = Single(
            skill,
            links: ids.Select(id => Link(id, skill)).ToList(),
            progress: new[] { Completed(ids[0]), Completed(ids[1]), Started(ids[2]) });

        Assert.Equal(50, result.ProgressPercent);
        Assert.Equal(4, result.TotalContentCount);
        Assert.Equal(2, result.CompletedContentCount);
        Assert.Equal(1, result.InProgressContentCount);
    }

    [Fact]
    public void ContentLinkedToMultipleSkills_ContributesToEach()
    {
        var aspNet = MakeSkill("ASP.NET Core");
        var restApi = MakeSkill("REST API");
        var shared = Guid.NewGuid();
        var other = Guid.NewGuid();

        var result = SkillProgressEngine.Calculate(
            UserId,
            new[] { aspNet, restApi },
            new[] { Link(shared, aspNet), Link(shared, restApi), Link(other, restApi) },
            new[] { Completed(shared) },
            Array.Empty<DomainQuiz>(),
            Array.Empty<QuizAttempt>());

        Assert.Equal(100, result.Single(r => r.SkillId == aspNet.Id).ProgressPercent);
        Assert.Equal(50, result.Single(r => r.SkillId == restApi.Id).ProgressPercent);
    }

    [Fact]
    public void SkillsOutsideSpecialization_AreNotCalculated()
    {
        var mine = MakeSkill("ASP.NET Core");
        var notMine = MakeSkill("Python");
        var content = Guid.NewGuid();
        var quiz = MakeQuiz(notMine);

        var result = SkillProgressEngine.Calculate(
            UserId,
            new[] { mine },
            new[] { Link(content, notMine) },
            new[] { Completed(content) },
            new[] { quiz },
            new[] { Attempt(quiz, 100) });

        var only = Assert.Single(result);
        Assert.Equal(mine.Id, only.SkillId);
        Assert.Equal(0, only.ProgressPercent);
        Assert.DoesNotContain(result, r => r.SkillId == notMine.Id);
    }

    [Fact]
    public void QuizWithNullSkillId_DoesNotContribute()
    {
        var skill = MakeSkill("ASP.NET Core");
        var unlinked = MakeQuiz(null);

        var result = Single(skill, quizzes: new[] { unlinked }, attempts: new[] { Attempt(unlinked, 100) });

        Assert.Equal(0, result.ProgressPercent);
        Assert.Equal(0, result.TotalQuizCount);
        Assert.Equal(0, result.QuizAttemptCount);
        Assert.Null(result.BestQuizScore);
    }

    [Fact]
    public void DuplicateContentProgress_IsCountedOnce()
    {
        var skill = MakeSkill("SQL");
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();

        var result = Single(
            skill,
            links: new[] { Link(c1, skill), Link(c2, skill) },
            progress: new[] { Completed(c1), Completed(c1), Started(c1) });

        // c1 tek içerik; yarım tamamlanmış kayıt onu "devam ediyor"a düşürmez.
        Assert.Equal(50, result.ProgressPercent);
        Assert.Equal(1, result.CompletedContentCount);
        Assert.Equal(0, result.InProgressContentCount);
    }

    [Fact]
    public void DuplicateContentSkillLinks_AreCountedOnce()
    {
        var skill = MakeSkill("SQL");
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();

        var result = Single(
            skill,
            links: new[] { Link(c1, skill), Link(c1, skill), Link(c2, skill) },
            progress: new[] { Completed(c1) });

        Assert.Equal(2, result.TotalContentCount);
        Assert.Equal(50, result.ProgressPercent);
    }

    [Fact]
    public void DuplicateSpecializationSkills_ProduceSingleResult()
    {
        var skill = MakeSkill("SQL");

        var result = SkillProgressEngine.Calculate(
            UserId,
            new[] { skill, skill },
            Array.Empty<ContentSkill>(),
            Array.Empty<UserContentProgress>(),
            Array.Empty<DomainQuiz>(),
            Array.Empty<QuizAttempt>());

        Assert.Single(result);
    }

    [Fact]
    public void RepeatedQuizAttempts_UseBestScore_AndDoNotInflate()
    {
        var skill = MakeSkill("ASP.NET Core");
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            quizzes: new[] { quiz },
            attempts: new[]
            {
                Attempt(quiz, 33, day: 1),
                Attempt(quiz, 67, day: 2),
                Attempt(quiz, 33, day: 3),
                Attempt(quiz, 67, day: 4),
            });

        // Deneme sayısı değil, en iyi skor belirleyici.
        Assert.Equal(67, result.ProgressPercent);
        Assert.Equal(4, result.QuizAttemptCount);
        Assert.Equal(67, result.BestQuizScore);
    }

    [Fact]
    public void LowerRetake_DoesNotReduceProgress_ButLatestScoreIsReported()
    {
        var skill = MakeSkill("ASP.NET Core");
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            quizzes: new[] { quiz },
            attempts: new[] { Attempt(quiz, 100, day: 1), Attempt(quiz, 33, day: 5) });

        Assert.Equal(100, result.ProgressPercent);
        Assert.Equal(100, result.BestQuizScore);
        Assert.Equal(33, result.LatestQuizScore);
    }

    [Fact]
    public void OtherUsersActivity_IsIgnored()
    {
        var skill = MakeSkill("SQL");
        var other = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            links: new[] { Link(c1, skill) },
            progress: new[] { Completed(c1, other) },
            quizzes: new[] { quiz },
            attempts: new[] { Attempt(quiz, 100, userId: other) });

        Assert.Equal(0, result.ProgressPercent);
        Assert.Equal(0, result.CompletedContentCount);
        Assert.Equal(0, result.QuizAttemptCount);
    }

    [Theory]
    [InlineData(250, 100)]
    [InlineData(-40, 0)]
    public void Progress_IsClampedToZeroToHundred(int rawScore, int expected)
    {
        var skill = MakeSkill("ASP.NET Core");
        var c1 = Guid.NewGuid();
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            links: new[] { Link(c1, skill) },
            progress: new[] { Completed(c1), Completed(c1) },
            quizzes: new[] { quiz },
            attempts: new[] { Attempt(quiz, rawScore) });

        Assert.InRange(result.ProgressPercent, 0, 100);
        Assert.InRange(result.BestQuizScore!.Value, 0, 100);

        // İçerik %100 + quiz (sıkıştırılmış) → ortalama
        Assert.Equal((100 + expected) / 2, result.ProgressPercent);
    }

    [Fact]
    public void FullCompletion_IsExactlyHundred()
    {
        var skill = MakeSkill("ASP.NET Core");
        var c1 = Guid.NewGuid();
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            links: new[] { Link(c1, skill) },
            progress: new[] { Completed(c1) },
            quizzes: new[] { quiz },
            attempts: new[] { Attempt(quiz, 100), Attempt(quiz, 100) });

        Assert.Equal(100, result.ProgressPercent);
    }

    [Fact]
    public void Rounding_IsAwayFromZero_AtMidpoint()
    {
        var skill = MakeSkill("SQL");
        var c1 = Guid.NewGuid();
        var quiz = MakeQuiz(skill);

        var result = Single(
            skill,
            links: new[] { Link(c1, skill) },
            quizzes: new[] { quiz },
            attempts: new[] { Attempt(quiz, 65) });

        // (0 + 65) / 2 = 32.5 → 33 (ToEven olsaydı 32 olurdu)
        Assert.Equal(33, result.ProgressPercent);
    }

    [Fact]
    public void Results_AreDeterministicallyOrderedByName()
    {
        var b = MakeSkill("SQL");
        var a = MakeSkill("C#");

        var first = SkillProgressEngine.Calculate(
            UserId, new[] { b, a },
            Array.Empty<ContentSkill>(), Array.Empty<UserContentProgress>(),
            Array.Empty<DomainQuiz>(), Array.Empty<QuizAttempt>());

        var second = SkillProgressEngine.Calculate(
            UserId, new[] { a, b },
            Array.Empty<ContentSkill>(), Array.Empty<UserContentProgress>(),
            Array.Empty<DomainQuiz>(), Array.Empty<QuizAttempt>());

        Assert.Equal(new[] { "C#", "SQL" }, first.Select(r => r.SkillName));
        Assert.Equal(first.Select(r => r.SkillId), second.Select(r => r.SkillId));
    }
}
