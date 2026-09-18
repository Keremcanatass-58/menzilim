namespace Menzilim.Application.Services.DailyPlan;

/// <summary>
/// Günlük plan üretimi için kullanıcı profili ve ilerleme bağlamı.
/// (AI kullanılmaz; tamamen deterministiktir.)
/// </summary>
public class DailyPlanGenerationContext
{
    public string ProfessionName { get; init; } = string.Empty;
    public string SpecializationName { get; init; } = string.Empty;
    public string ExperienceLevel { get; init; } = string.Empty;
    public string CareerGoal { get; init; } = string.Empty;
    public int DailyLearningMinutes { get; init; }
    public int CompletedContentCount { get; init; }
    public int InProgressContentCount { get; init; }
    public int QuizAttemptCount { get; init; }

    // Learn görevi için seçilen içerik (yoksa null kalır).
    public Guid? LearnContentId { get; init; }
    public string? LearnContentTitle { get; init; }
    public bool LearnContentIsContinuation { get; init; }
}

public class GeneratedTask
{
    public required string Title { get; init; }
    public required string Description { get; init; }
    public required string TaskType { get; init; }
    public required int EstimatedMinutes { get; init; }
    public Guid? ContentId { get; init; }
}

/// <summary>
/// Kullanıcı profiline ve ilerlemesine göre günlük görevleri deterministik
/// biçimde üretir. Aynı bağlam her zaman aynı planı verir (rastgelelik yok).
/// </summary>
public static class DailyPlanGenerator
{
    public const int DefaultMinutes = 60;
    public const int MinMinutes = 10;

    public static string BuildPlanTitle(DailyPlanGenerationContext context)
    {
        var focus = FocusLabel(context);

        return string.IsNullOrWhiteSpace(focus)
            ? "Bugünün Öğrenme Planı"
            : $"{focus} · Günlük Plan";
    }

    public static IReadOnlyList<GeneratedTask> Generate(
        DailyPlanGenerationContext context)
    {
        var minutes = NormalizeMinutes(context.DailyLearningMinutes);
        var focus = FocusLabel(context);

        // Katman seçimi. Ağırlıklar tamsayı orandır; sıra korunur.
        var slots = new List<(string Type, int Weight)>();

        if (minutes <= 40)
        {
            // Kısa plan: yalnızca öğren + test.
            slots.Add(("Learn", 3));
            slots.Add(("Quiz", 2));
        }
        else if (minutes < 90)
        {
            // Standart plan (ör. 60 dk → 25/20/15).
            slots.Add(("Learn", 5));
            slots.Add(("Practice", 4));
            slots.Add(("Quiz", 3));
        }
        else
        {
            // Kapsamlı plan: öğren + uygula + test + pekiştir.
            slots.Add(("Learn", 7));
            slots.Add(("Practice", 6));
            slots.Add(("Quiz", 3));
            slots.Add(("Review", 4));
        }

        var durations = Distribute(
            minutes,
            slots.Select(s => s.Weight).ToList());

        var tasks = new List<GeneratedTask>();
        for (var i = 0; i < slots.Count; i++)
        {
            tasks.Add(BuildTask(slots[i].Type, durations[i], focus, context));
        }

        return tasks;
    }

    private static int NormalizeMinutes(int minutes)
    {
        if (minutes <= 0)
        {
            return DefaultMinutes;
        }

        return minutes < MinMinutes ? MinMinutes : minutes;
    }

    private static string FocusLabel(DailyPlanGenerationContext context)
    {
        if (!string.IsNullOrWhiteSpace(context.SpecializationName))
        {
            return context.SpecializationName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(context.ProfessionName))
        {
            return context.ProfessionName.Trim();
        }

        return string.Empty;
    }

    /// <summary>
    /// Toplam süreyi tamsayı ağırlıklara göre "largest remainder" yöntemiyle
    /// dağıtır. Sonuç deterministiktir ve toplamı tam olarak korur.
    /// </summary>
    private static List<int> Distribute(int total, List<int> weights)
    {
        var sumWeights = weights.Sum();

        var allocation = weights
            .Select(w => total * w / sumWeights)
            .ToList();

        var remainders = weights
            .Select(w => total * w % sumWeights)
            .ToList();

        var leftover = total - allocation.Sum();

        var order = Enumerable
            .Range(0, weights.Count)
            .OrderByDescending(i => remainders[i])
            .ThenBy(i => i)
            .ToList();

        for (var k = 0; k < leftover; k++)
        {
            allocation[order[k]]++;
        }

        return allocation;
    }

    private static GeneratedTask BuildTask(
        string type,
        int minutes,
        string focus,
        DailyPlanGenerationContext context)
    {
        var focusSuffix = string.IsNullOrWhiteSpace(focus)
            ? string.Empty
            : $" ({focus})";

        var goal = string.IsNullOrWhiteSpace(context.CareerGoal)
            ? "kariyer hedefin"
            : context.CareerGoal.Trim();

        return type switch
        {
            "Learn" => new GeneratedTask
            {
                TaskType = "Learn",
                Title = "Bugünün Konusunu Öğren" + focusSuffix,
                Description = BuildLearnDescription(context, goal),
                EstimatedMinutes = minutes,
                ContentId = context.LearnContentId,
            },
            "Practice" => new GeneratedTask
            {
                TaskType = "Practice",
                Title = "Uygulama Yap" + focusSuffix,
                Description =
                    "Öğrendiğin konuyla ilgili küçük bir uygulama gerçekleştir.",
                EstimatedMinutes = minutes,
            },
            "Quiz" => new GeneratedTask
            {
                TaskType = "Quiz",
                Title = "Bilgini Test Et" + focusSuffix,
                Description = context.QuizAttemptCount == 0
                    ? "İlk quiz'ini çözerek başlangıç seviyeni ölç."
                    : "Kısa bir test ile bilgini tazele.",
                EstimatedMinutes = minutes,
            },
            "Review" => new GeneratedTask
            {
                TaskType = "Review",
                Title = "Öğrendiklerini Pekiştir" + focusSuffix,
                Description = context.CompletedContentCount > 0
                    ? $"Tamamladığın {context.CompletedContentCount} içeriği gözden geçir ve not çıkar."
                    : "Bugün öğrendiklerini özetleyerek pekiştir.",
                EstimatedMinutes = minutes,
            },
            _ => new GeneratedTask
            {
                TaskType = type,
                Title = "Görev" + focusSuffix,
                Description = "Günlük gelişim görevin.",
                EstimatedMinutes = minutes,
            },
        };
    }

    private static string BuildLearnDescription(
        DailyPlanGenerationContext context,
        string goal)
    {
        string basePart;
        if (!string.IsNullOrWhiteSpace(context.LearnContentTitle))
        {
            var title = context.LearnContentTitle!.Trim();
            basePart = context.LearnContentIsContinuation
                ? $"Devam eden içeriğine kaldığın yerden devam et: \"{title}\"."
                : $"Bugün için önerilen içerik: \"{title}\".";
        }
        else
        {
            basePart = context.InProgressContentCount > 0
                ? $"Devam eden içeriğinden kaldığın yerden ilerle. Hedef: {goal}."
                : $"{goal} doğrultusunda bugünün konusunu öğren.";
        }

        if (!string.IsNullOrWhiteSpace(context.ExperienceLevel))
        {
            return $"{context.ExperienceLevel.Trim()} seviyene uygun: {basePart}";
        }

        return basePart;
    }
}
