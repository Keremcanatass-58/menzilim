using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Menzilim.Application.Interfaces;
using Menzilim.Application.Interfaces.Repositories;
using Menzilim.Application.Services.Auth;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Infrastructure.Data;
using Menzilim.Infrastructure.Repositories;
using Menzilim.Infrastructure.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

builder.Services.AddDbContext<MenzilimDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")
    ));

builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IPasswordService, PasswordService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();

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
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => new
{
    name = "MENZİLİM API",
    status = "online",
    version = "1.0.0"
});
app.MapPost("/api/auth/register", async (
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

app.MapPost("/api/auth/login", async (
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

app.Run();