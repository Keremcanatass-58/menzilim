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
    public string? LearnFocusSkillName { get; init; }

    // Practice görevi için Learn'den FARKLI ikinci içerik (yoksa null kalır).
    public Guid? PracticeContentId { get; init; }
    public string? PracticeContentTitle { get; init; }
    public string? PracticeFocusSkillName { get; init; }

    // Living Project'in sıradaki (Available) adımı; varsa günün ana görevi
    // bu adımdır. Yoksa plan eskisi gibi Learn ile başlar.
    public Guid? ProjectStepId { get; init; }
    public string? ProjectStepTitle { get; init; }
    public string? ProjectStepDescription { get; init; }
    public int ProjectStepOrder { get; init; }
    public int ProjectTotalSteps { get; init; }
    public int ProjectStepMinutes { get; init; }
    public string? ProjectName { get; init; }
    public Guid? ProjectStepContentId { get; init; }
    public string? ProjectStepSkillName { get; init; }

    public bool HasProjectStep =>
        ProjectStepId is not null &&
        !string.IsNullOrWhiteSpace(ProjectStepTitle);
}

public class GeneratedTask
{
    public required string Title { get; init; }
    public required string Description { get; init; }
    public required string TaskType { get; init; }
    public required int EstimatedMinutes { get; init; }
    public Guid? ContentId { get; init; }

    /// <summary>Görev bir proje adımından üretildiyse o adım.</summary>
    public Guid? UserProjectStepId { get; init; }
}

/// <summary>
/// Kullanıcı profiline ve ilerlemesine göre günlük görevleri deterministik
/// biçimde üretir. Aynı bağlam her zaman aynı planı verir (rastgelelik yok).
/// </summary>
public static class DailyPlanGenerator
{
    public const int DefaultMinutes = 60;
    public const int MinMinutes = 10;

    /// <summary>Bir göreve ayrılabilecek en kısa süre.</summary>
    public const int MinSlotMinutes = 5;

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

        // Proje adımı varsa günün ana görevi odur: en başa alınır ve
        // "uygulama" görevinin yerini tutar (asıl uygulama projede yapılır).
        // Öğrenme ve test görevleri korunur.
        if (context.HasProjectStep)
        {
            // Kısa günde plan iki görevdir: proje adımı + test. Uzun günlerde
            // "uygulama" görevi düşer; öğrenme ve test korunur.
            var replaced = minutes <= 40 ? "Learn" : "Practice";
            var index = slots.FindIndex(slot => slot.Type == replaced);

            if (index >= 0)
            {
                slots.RemoveAt(index);
            }

            slots.Insert(0, ("Project", 5));
        }

        var durations = context.HasProjectStep
            ? DistributeWithFixedFirst(
                minutes,
                slots.Select(s => s.Weight).ToList(),
                context.ProjectStepMinutes)
            : Distribute(minutes, slots.Select(s => s.Weight).ToList());

        var tasks = new List<GeneratedTask>();
        for (var i = 0; i < slots.Count; i++)
        {
            // Süresi sıfıra düşen görev plana eklenmez (kısa günlerde olur).
            if (durations[i] <= 0)
            {
                continue;
            }

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

    /// <summary>
    /// İlk göreve (proje adımı) kendi tahmini süresini verir; kalan süreyi
    /// diğer görevlere ağırlıklarına göre böler. Toplam hiçbir zaman günlük
    /// süreyi aşmaz. Kalan süre yetmiyorsa plan yalnızca proje adımından oluşur.
    /// </summary>
    private static List<int> DistributeWithFixedFirst(
        int total,
        List<int> weights,
        int firstDesiredMinutes)
    {
        var otherCount = weights.Count - 1;

        if (otherCount <= 0)
        {
            return new List<int> { total };
        }

        var maxForFirst = total - otherCount * MinSlotMinutes;

        if (maxForFirst < MinSlotMinutes)
        {
            // Gün çok kısa: tek görev, proje adımı.
            var single = new List<int> { total };
            single.AddRange(Enumerable.Repeat(0, otherCount));

            return single;
        }

        var desired = firstDesiredMinutes <= 0 ? total / weights.Count : firstDesiredMinutes;
        var first = Math.Clamp(desired, MinSlotMinutes, maxForFirst);

        var rest = Distribute(total - first, weights.Skip(1).ToList());

        var result = new List<int> { first };
        result.AddRange(rest);

        return result;
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
            "Project" => new GeneratedTask
            {
                TaskType = "Project",
                // Başlık doğrudan adımın başlığıdır: kullanıcı ne yapacağını
                // düşünmeden görür.
                Title = context.ProjectStepTitle!.Trim(),
                Description = BuildProjectDescription(context),
                EstimatedMinutes = minutes,
                ContentId = context.ProjectStepContentId,
                UserProjectStepId = context.ProjectStepId,
            },
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
                Description = BuildPracticeDescription(context),
                EstimatedMinutes = minutes,
                ContentId = context.PracticeContentId,
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

    private static string BuildPracticeDescription(
        DailyPlanGenerationContext context)
    {
        if (string.IsNullOrWhiteSpace(context.PracticeContentTitle))
        {
            return "Öğrendiğin konuyla ilgili küçük bir uygulama gerçekleştir.";
        }

        var title = context.PracticeContentTitle.Trim();

        return string.IsNullOrWhiteSpace(context.PracticeFocusSkillName)
            ? $"\"{title}\" içeriği üzerinden küçük bir uygulama gerçekleştir."
            : $"{context.PracticeFocusSkillName.Trim()} becerin için \"{title}\" içeriği üzerinden küçük bir uygulama gerçekleştir.";
    }

    /// <summary>
    /// Deneyim seviyesinin görünen karşılığı. Ham İngilizce değer kullanıcıya
    /// gösterilmez.
    /// </summary>
    private static string LevelLabel(string level) =>
        level.Trim().ToLowerInvariant() switch
        {
            "beginner" => "Başlangıç",
            "intermediate" => "Orta",
            "advanced" => "İleri",
            _ => level.Trim(),
        };

    /// <summary>
    /// Proje adımı görevinin açıklaması: adımın kendi açıklaması ve hangi
    /// projeye ait olduğu. Hedef cümlesini istemci ayrıca gösterir.
    /// </summary>
    private static string BuildProjectDescription(
        DailyPlanGenerationContext context)
    {
        var parts = new List<string>();

        if (!string.IsNullOrWhiteSpace(context.ProjectStepDescription))
        {
            parts.Add(context.ProjectStepDescription!.Trim());
        }

        if (!string.IsNullOrWhiteSpace(context.ProjectName))
        {
            parts.Add($"\"{context.ProjectName!.Trim()}\" projesinin bir adımı.");
        }

        return parts.Count == 0
            ? "Projenin sıradaki adımı."
            : string.Join(" ", parts);
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

            if (!string.IsNullOrWhiteSpace(context.LearnFocusSkillName))
            {
                basePart += $" Odak beceri: {context.LearnFocusSkillName.Trim()}.";
            }
        }
        else
        {
            basePart = context.InProgressContentCount > 0
                ? $"Devam eden içeriğinden kaldığın yerden ilerle. Hedef: {goal}."
                : $"{goal} doğrultusunda bugünün konusunu öğren.";
        }

        if (!string.IsNullOrWhiteSpace(context.ExperienceLevel))
        {
            return $"{LevelLabel(context.ExperienceLevel)} seviyene uygun: {basePart}";
        }

        return basePart;
    }
}
