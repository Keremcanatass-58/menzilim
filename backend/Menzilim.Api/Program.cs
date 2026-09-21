using System.Security.Claims;
using System.Text;

using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Menzilim.Application.Interfaces.Content;
using Menzilim.Application.Interfaces.Skills;
using Menzilim.Application.Services.Skills;
using Menzilim.Application.DTOs.Content;
using Menzilim.Application.Services.Content;
using Menzilim.Application.Services;
using Menzilim.Application.Interfaces.ContentProfession;
using Menzilim.Application.Services.ContentProfession;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Dashboard;
using Menzilim.Application.DTOs.Onboarding;
using Menzilim.Application.Interfaces;
using Menzilim.Application.Interfaces.Dashboard;
using Menzilim.Application.Interfaces.DailyPlan;
using Menzilim.Application.Interfaces.Onboarding;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Services.Auth;
using Menzilim.Application.Services.Dashboard;
using Menzilim.Application.Services.DailyPlan;
using Menzilim.Application.Services.Onboarding;
using Menzilim.Application.DTOs.Quiz;
using Menzilim.Application.Interfaces.Quiz;
using Menzilim.Application.Services.Quiz;
using Menzilim.Application.Interfaces.AI;
using Menzilim.Application.DTOs.AICoach;
using Menzilim.Application.Interfaces.AICoach;
using Menzilim.Application.Services.AICoach;
using Menzilim.Application.Interfaces.Progress;
using Menzilim.Application.Services.Progress;
using Menzilim.Application.Interfaces.News;
using Menzilim.Application.Services.News;
using Menzilim.Application.Interfaces.Projects;
using Menzilim.Application.Services.Projects;
using Menzilim.Infrastructure.Configuration;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Services.AI;
using Menzilim.Infrastructure.Data.Seed;
using Menzilim.Infrastructure.Repositories;
using Menzilim.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();


// ==============================
// DATABASE
// ==============================

builder.Services.AddDbContext<MenzilimDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")
    ));


// ==============================
// APPLICATION SERVICES
// ==============================

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IOnboardingService, OnboardingService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IDailyPlanService, DailyPlanService>();
builder.Services.AddScoped<IDailyPlanRepository, DailyPlanRepository>();
builder.Services.AddScoped<IContentService, ContentService>();
builder.Services.AddScoped<IContentRepository, ContentRepository>();
builder.Services.AddScoped<IContentRecommendationService, ContentRecommendationService>();
builder.Services.AddScoped<ISkillService, SkillService>();
builder.Services.AddScoped<ISkillGapService, SkillGapService>();
builder.Services.AddScoped<ISkillRepository, SkillRepository>();
builder.Services.AddScoped<IContentProfessionService, ContentProfessionService>();
builder.Services.AddScoped<IContentProfessionRepository, ContentProfessionRepository>();
builder.Services.AddScoped<IContentProgressService, ContentProgressService>();
builder.Services.AddScoped<IUserContentProgressRepository, UserContentProgressRepository>();
builder.Services.AddScoped<IQuizService, QuizService>();
builder.Services.AddScoped<IQuizRepository, QuizRepository>();
builder.Services.AddScoped<IAICoachService, AICoachService>();
builder.Services.AddScoped<IProgressService, ProgressService>();
builder.Services.AddScoped<INewsService, NewsService>();
builder.Services.AddScoped<INewsRepository, NewsRepository>();
builder.Services.AddScoped<IUserProjectService, UserProjectService>();
builder.Services.AddScoped<IUserProjectRepository, UserProjectRepository>();


// ==============================
// REPOSITORIES
// ==============================

builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IDailyPlanRepository, DailyPlanRepository>();


// ==============================
// INFRASTRUCTURE SERVICES
// ==============================

builder.Services.AddScoped<IPasswordService, PasswordService>();
builder.Services.AddScoped<IJwtService, JwtService>();


// ==============================
// AI PROVIDER
// ==============================

// Gizli olmayan ayarlar yapılandırmadan bağlanır; API anahtarı yalnızca
// ortam değişkeni (AIProvider__ApiKey veya ANTHROPIC_API_KEY) / User Secrets
// üzerinden gelir, koda veya appsettings.json'a yazılmaz.
builder.Services.Configure<AIProviderOptions>(options =>
{
    builder.Configuration
        .GetSection(AIProviderOptions.SectionName)
        .Bind(options);

    options.ApiKey ??= Environment.GetEnvironmentVariable("ANTHROPIC_API_KEY");
});

// "anthropic" seçilirse gerçek sağlayıcı, aksi halde mock kullanılır.
// Anahtar eksikse startup çökmeden, çağrı anında açık hata döner.
var aiProviderName =
    builder.Configuration["AIProvider:Provider"] ?? "mock";

if (string.Equals(aiProviderName, "anthropic", StringComparison.OrdinalIgnoreCase))
{
    builder.Services.AddScoped<IAIProvider, AnthropicAIProvider>();
}
else
{
    builder.Services.AddScoped<IAIProvider, MockAIProvider>();
}


// ==============================
// JWT AUTHENTICATION
// ==============================

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("JWT Key bulunamadı.");

builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,

            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)),

            ValidateIssuer = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],

            ValidateAudience = true,
            ValidAudience = builder.Configuration["Jwt:Audience"],

            ValidateLifetime = true,

            ClockSkew = TimeSpan.Zero,

            NameClaimType = ClaimTypes.NameIdentifier
        };
    });

builder.Services.AddAuthorization();


// ==============================
// CORS
// ==============================

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWeb", policy =>
    {
        policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});


var app = builder.Build();


// ==============================
// DATABASE SEED
// ==============================

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider
        .GetRequiredService<MenzilimDbContext>();

    var seedLogger = scope.ServiceProvider
        .GetRequiredService<ILoggerFactory>()
        .CreateLogger(nameof(DatabaseSeeder));

    await DatabaseSeeder.SeedAsync(db, seedLogger);

    // Skill'lere bağlandığı için DatabaseSeeder'dan sonra çalışır.
    await ContentSeeder.SeedAsync(db, seedLogger);

    // Haberler de skill'lere bağlanır.
    await NewsSeeder.SeedAsync(db, seedLogger);

    // Proje şablonları içerik ve skill'lere bağlandığı için en sonda çalışır.
    await ProjectSeeder.SeedAsync(db, seedLogger);
}


// ==============================
// DEVELOPMENT
// ==============================

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}


// ==============================
// MIDDLEWARE
// ==============================

app.UseHttpsRedirection();

app.UseCors("FlutterWeb");

app.UseAuthentication();

app.UseAuthorization();


// ==============================
// HEALTH CHECK
// ==============================

app.MapGet("/", () => new
{
    name = "MENZİLİM API",
    status = "online",
    version = "1.0.0"
});


// ==============================
// PROFESSIONS
// ==============================

app.MapGet("/api/professions", async (MenzilimDbContext db) =>
{
    // Hazır olmayan meslekler de dönülür; istemci bunları "Yakında" olarak
    // gösterir ve seçtirmez (boş dashboard oluşmaz).
    var professions = await db.Professions
        .Where(x => x.IsActive)
        .OrderByDescending(x => x.IsAvailable)
        .ThenBy(x => x.Name)
        .Select(x => new
        {
            x.Id,
            x.Name,
            x.Description,
            x.IsAvailable
        })
        .ToListAsync();

    return Results.Ok(professions);
});


// ==============================
// SPECIALIZATIONS
// ==============================

app.MapGet(
    "/api/professions/{professionId:guid}/specializations",
    async (
        Guid professionId,
        MenzilimDbContext db) =>
    {
        var professionExists = await db.Professions
            .AnyAsync(x =>
                x.Id == professionId &&
                x.IsActive);

        if (!professionExists)
        {
            return Results.NotFound(new
            {
                message = "Meslek bulunamadı."
            });
        }

        var specializations = await db.Specializations
            .Where(x =>
                x.ProfessionId == professionId &&
                x.IsActive)
            .OrderBy(x => x.Name)
            .Select(x => new
            {
                x.Id,
                x.Name,
                x.Description
            })
            .ToListAsync();

        return Results.Ok(specializations);
    });


// ==============================
// SKILLS - BY SPECIALIZATION
// ==============================

app.MapGet(
    "/api/specializations/{specializationId:guid}/skills",
    async (
        Guid specializationId,
        ISkillService skillService) =>
    {
        try
        {
            var response =
                await skillService.GetBySpecializationAsync(specializationId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    });


// ==============================
// SKILLS - GET ME
// ==============================

app.MapGet(
    "/api/skills/me",
    async (
        ClaimsPrincipal user,
        ISkillService skillService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
            return Results.Unauthorized();

        try
        {
            var response =
                await skillService.GetMyProgressAsync(userId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();


// ==============================
// AUTH - REGISTER
// ==============================

app.MapPost(
    "/api/auth/register",
    async (
        RegisterRequest request,
        IAuthService authService) =>
    {
        try
        {
            var response = await authService.RegisterAsync(request);

            return Results.Ok(response);
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new
            {
                message = ex.Message
            });
        }
    });


// ==============================
// AUTH - LOGIN
// ==============================

app.MapPost(
    "/api/auth/login",
    async (
        LoginRequest request,
        IAuthService authService) =>
    {
        var response = await authService.LoginAsync(request);

        if (response is null)
        {
            return Results.Unauthorized();
        }

        return Results.Ok(response);
    });


// ==============================
// ONBOARDING - GET ME
// ==============================

app.MapGet(
    "/api/onboarding/me",
    async (
        ClaimsPrincipal user,
        IOnboardingService onboardingService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var response =
            await onboardingService.GetAsync(userId);

        return response is null
            ? Results.NotFound(new
            {
                message = "Onboarding profili bulunamadı."
            })
            : Results.Ok(response);
    })
    .RequireAuthorization();


// ==============================
// ONBOARDING - SAVE
// ==============================

app.MapPost(
    "/api/onboarding",
    async (
        OnboardingRequest request,
        ClaimsPrincipal user,
        IOnboardingService onboardingService,
        MenzilimDbContext db) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        // Hazır olmayan meslek seçilemez: kullanıcı boş bir deneyime düşmesin.
        var professionIsAvailable = await db.Professions
            .AnyAsync(p =>
                p.Id == request.ProfessionId &&
                p.IsActive &&
                p.IsAvailable);

        if (!professionIsAvailable)
        {
            return Results.BadRequest(new
            {
                message = "Bu meslek henüz kullanıma açık değil."
            });
        }

        try
        {
            var response =
                await onboardingService.SaveAsync(
                    userId,
                    request);

            return Results.Ok(response);
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();


// ==============================
// DASHBOARD - GET ME
// ==============================

app.MapGet(
    "/api/dashboard/me",
    async (
        ClaimsPrincipal user,
        IDashboardService dashboardService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var response =
            await dashboardService.GetAsync(userId);

        return response is null
            ? Results.NotFound(new
            {
                message = "Dashboard profili bulunamadı."
            })
            : Results.Ok(response);
    })
    .RequireAuthorization();


// ==============================
// DAILY PLAN - GET ME
// ==============================

app.MapGet(
    "/api/daily-plan/me",
    async (
        ClaimsPrincipal user,
        IDailyPlanService dailyPlanService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var response =
            await dailyPlanService.GetTodayAsync(userId);

        return Results.Ok(response);
    })
    .RequireAuthorization();


// ==============================
// DAILY PLAN - COMPLETE TASK
// ==============================

app.MapPost(
    "/api/daily-plan/tasks/{taskId:guid}/complete",
    async (
        Guid taskId,
        ClaimsPrincipal user,
        IDailyPlanService dailyPlanService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        try
        {
            var response =
                await dailyPlanService.CompleteTaskAsync(
                    userId,
                    taskId);

            return Results.Ok(response);
        }
        catch (InvalidOperationException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
        catch (UnauthorizedAccessException)
        {
            return Results.Forbid();
        }
    })
    .RequireAuthorization();

// ==============================
// CONTENT - GET ALL
// ==============================

app.MapGet(
    "/api/content",
    async (
        IContentService contentService) =>
    {
        var response =
            await contentService.GetAllAsync();

        return Results.Ok(response);
    });


// ==============================
// CONTENT - GET BY ID
// ==============================

app.MapGet(
    "/api/content/{contentId:guid}",
    async (
        Guid contentId,
        IContentService contentService) =>
    {
        var response =
            await contentService.GetByIdAsync(contentId);

        return response is null
            ? Results.NotFound(new
            {
                message = "İçerik bulunamadı."
            })
            : Results.Ok(response);
    });

 // CONTENT - CREATE
// Katalog yazma uçları: anonim erişime kapalı (kimliği doğrulanmış çağrı).
app.MapPost(
    "/api/content",
    async (
        CreateContentRequest request,
        IContentService contentService) =>
    {
        var response = await contentService.CreateAsync(request);

        return Results.Created(
            $"/api/content/{response.Id}",
            response);
    })
    .RequireAuthorization();

// ==============================
// CONTENT - PROFESSION ASSIGN
// ==============================

app.MapPost(
    "/api/content/profession",
    async (
        CreateContentProfessionRequest request,
        IContentProfessionService contentProfessionService) =>
    {
        var created = await contentProfessionService.AddAsync(request);

        return created
            ? Results.Ok(new
            {
                message = "İçerik meslek ile eşleştirildi."
            })
            : Results.Conflict(new
            {
                message = "Bu içerik zaten bu meslek ile eşleştirilmiş."
            });
    })
    .RequireAuthorization();

// ==============================
// CONTENT - RECOMMENDATIONS
// ==============================

app.MapGet(
    "/api/content/recommendations",
    async (
        ClaimsPrincipal user,
        IContentRecommendationService recommendationService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
            return Results.Unauthorized();

        try
        {
            var response =
                await recommendationService.GetForUserAsync(userId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();

// ==============================
// CONTENT - GET ME
// ==============================

app.MapGet(
    "/api/content/me",
    async (
        ClaimsPrincipal user,
        IUserRepository userRepository,
        IContentService contentService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var currentUser =
            await userRepository.GetByIdWithProfileDetailsAsync(userId);

        if (currentUser is null)
        {
            return Results.NotFound(new
            {
                message = "Kullanıcı bulunamadı."
            });
        }

        if (currentUser.Profile is null)
        {
            return Results.NotFound(new
            {
                message = "Kullanıcı profili bulunamadı."
            });
        }

        var professionId = currentUser.Profile.ProfessionId;

        var response =
            await contentService.GetByProfessionAsync(professionId);

        return Results.Ok(response);
    })
    .RequireAuthorization();


// ==============================
// CONTENT PROGRESS - START
// ==============================

app.MapPost(
    "/api/content/{contentId:guid}/start",
    async (
        Guid contentId,
        ClaimsPrincipal user,
        IContentProgressService contentProgressService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
            return Results.Unauthorized();

        try
        {
            var response =
                await contentProgressService.StartAsync(
                    userId,
                    contentId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();


// ==============================
// CONTENT PROGRESS - COMPLETE
// ==============================

app.MapPost(
    "/api/content/{contentId:guid}/complete",
    async (
        Guid contentId,
        ClaimsPrincipal user,
        IContentProgressService contentProgressService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
            return Results.Unauthorized();

        try
        {
            var response =
                await contentProgressService.CompleteAsync(
                    userId,
                    contentId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();


// CONTENT PROGRESS - GET
app.MapGet(
    "/api/content/{contentId:guid}/progress",
    async (
        Guid contentId,
        ClaimsPrincipal user,
        IContentProgressService contentProgressService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
            return Results.Unauthorized();

        try
        {
            var response =
                await contentProgressService.GetAsync(
                    userId,
                    contentId);

            if (response is null)
            {
                return Results.Ok(new
                {
                    contentId,
                    isStarted = false,
                    isCompleted = false,
                    startedAt = (DateTime?)null,
                    completedAt = (DateTime?)null
                });
            }

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();

// ==============================
// QUIZZES - GET ALL ACTIVE
// ==============================
app.MapGet(
    "/api/quizzes",
    async (IQuizService quizService) =>
    {
        var response = await quizService.GetAllActiveAsync();
        return Results.Ok(response);
    });

// ==============================
// QUIZZES - GET ACTIVE / DAILY
// ==============================
app.MapGet(
    "/api/quizzes/active",
    async (IQuizService quizService) =>
    {
        var response = await quizService.GetActiveQuizAsync();
        return response is null
            ? Results.NotFound(new { message = "Aktif quiz bulunamadı." })
            : Results.Ok(response);
    });

// ==============================
// QUIZZES - GET BY ID
// ==============================
app.MapGet(
    "/api/quizzes/{quizId:guid}",
    async (Guid quizId, IQuizService quizService) =>
    {
        var response = await quizService.GetByIdAsync(quizId);
        return response is null
            ? Results.NotFound(new { message = "Quiz bulunamadı." })
            : Results.Ok(response);
    });

// ==============================
// QUIZZES - SUBMIT
// ==============================
app.MapPost(
    "/api/quizzes/{quizId:guid}/submit",
    async (
        Guid quizId,
        QuizSubmitRequest request,
        ClaimsPrincipal user,
        IQuizService quizService) =>
    {
        var userIdClaim = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        try
        {
            var response = await quizService.SubmitAsync(userId, quizId, request);
            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { message = ex.Message });
        }
    })
    .RequireAuthorization();

// ==============================
// AI COACH - ASK
// ==============================
app.MapPost(
    "/api/ai-coach/ask",
    async (
        AICoachAskRequest request,
        ClaimsPrincipal user,
        IAICoachService aiCoachService) =>
    {
        var userIdClaim = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        try
        {
            var response = await aiCoachService.AskAsync(userId, request);
            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new { message = ex.Message });
        }
    })
    .RequireAuthorization();

// ==============================
// PROGRESS - GET ME
// ==============================

app.MapGet(
    "/api/progress/me",
    async (
        ClaimsPrincipal user,
        IProgressService progressService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var response = await progressService.GetMyProgressAsync(userId);
        return Results.Ok(response);
    })
    .RequireAuthorization();

// ==============================
// NEWS - GET ME
// ==============================

app.MapGet(
    "/api/news/me",
    async (
        ClaimsPrincipal user,
        INewsService newsService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        // Onboarding yapılmamışsa kişiselleştirilecek alan yok: boş liste.
        var response = await newsService.GetForUserAsync(userId);
        return Results.Ok(response);
    })
    .RequireAuthorization();

// ==============================
// PROJECTS (LIVING PROJECT)
// ==============================

app.MapGet(
    "/api/skills/gap/me",
    async (
        ClaimsPrincipal user,
        ISkillGapService skillGapService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        try
        {
            var response = await skillGapService.GetForUserAsync(userId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();

app.MapGet(
    "/api/projects/me",
    async (
        ClaimsPrincipal user,
        IUserProjectService projectService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        try
        {
            // Uzmanlığa uygun şablon varsa proje ilk çağrıda oluşturulur.
            var response = await projectService.GetMyProjectsAsync(userId);

            return Results.Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return Results.NotFound(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();

app.MapGet(
    "/api/projects/me/{projectId:guid}",
    async (
        Guid projectId,
        ClaimsPrincipal user,
        IUserProjectService projectService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var response = await projectService.GetByIdAsync(userId, projectId);

        // Başkasının projesi de bulunamadı sayılır (varlık sızdırılmaz).
        if (response is null)
        {
            return Results.NotFound(new
            {
                message = "Proje bulunamadı."
            });
        }

        return Results.Ok(response);
    })
    .RequireAuthorization();

app.MapPost(
    "/api/projects/me/steps/{stepId:guid}/complete",
    async (
        Guid stepId,
        ClaimsPrincipal user,
        IUserProjectService projectService) =>
    {
        var userIdClaim =
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        try
        {
            var response =
                await projectService.CompleteStepAsync(userId, stepId);

            if (response is null)
            {
                return Results.NotFound(new
                {
                    message = "Adım bulunamadı."
                });
            }

            return Results.Ok(response);
        }
        catch (InvalidOperationException ex)
        {
            return Results.BadRequest(new
            {
                message = ex.Message
            });
        }
    })
    .RequireAuthorization();

app.Run();