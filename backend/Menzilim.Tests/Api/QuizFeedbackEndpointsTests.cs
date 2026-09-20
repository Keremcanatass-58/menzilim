using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Menzilim.Application.DTOs.Auth;
using Menzilim.Application.DTOs.Quiz;
using Xunit;

namespace Menzilim.Tests.Api;

/// <summary>
/// Quiz gönderiminin soru bazlı geri bildirim (doğru şık + açıklama)
/// döndürdüğünü gerçek HTTP akışıyla test eder.
/// </summary>
public sealed class QuizFeedbackEndpointsTests : IDisposable
{
    private readonly MenzilimApiFactory _factory = new();
    private readonly HttpClient _client;

    public QuizFeedbackEndpointsTests()
    {
        _client = _factory.CreateClient();
    }

    public void Dispose()
    {
        _client.Dispose();
        _factory.Dispose();
    }

    private async Task<string> RegisterAsync()
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"quiz-{Guid.NewGuid():N}@menzilim.test",
            password = "Test1234!",
            firstName = "Test",
            lastName = "Kullanıcı",
        });

        register.EnsureSuccessStatusCode();

        return (await register.Content.ReadFromJsonAsync<AuthResponse>())!.Token;
    }

    private async Task<HttpResponseMessage> SendAsync(
        HttpMethod method,
        string url,
        string? token = null,
        object? body = null)
    {
        using var request = new HttpRequestMessage(method, url);

        if (token is not null)
        {
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", token);
        }

        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }

        return await _client.SendAsync(request);
    }

    /// <summary>Seed edilmiş bir quiz'in id'si ve doğru cevap anahtarı.</summary>
    private async Task<(Guid QuizId, Dictionary<Guid, string> CorrectOptions)>
        GetSeededQuizAsync()
    {
        await using var db = _factory.CreateDbContext();

        var quiz = await db.Quizzes
            .Include(q => q.Questions)
            .Where(q => q.IsActive && q.Questions.Any())
            .OrderBy(q => q.Title)
            .FirstAsync();

        return (
            quiz.Id,
            quiz.Questions.ToDictionary(q => q.Id, q => q.CorrectOption));
    }

    [Fact]
    public async Task Seed_FillsExplanationsForEveryQuestion()
    {
        await using var db = _factory.CreateDbContext();

        var missing = await db.Questions
            .Where(q => q.Explanation == null || q.Explanation == "")
            .CountAsync();

        Assert.Equal(0, missing);
    }

    [Fact]
    public async Task Submit_AllCorrect_ReturnsPerQuestionFeedback()
    {
        var token = await RegisterAsync();
        var (quizId, correctOptions) = await GetSeededQuizAsync();

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/quizzes/{quizId}/submit",
            token,
            new
            {
                answers = correctOptions
                    .Select(pair => new
                    {
                        questionId = pair.Key,
                        selectedOption = pair.Value
                    })
                    .ToList()
            });

        response.EnsureSuccessStatusCode();

        var result = await response
            .Content.ReadFromJsonAsync<QuizSubmitResultResponse>();

        Assert.Equal(100, result!.Score);
        Assert.Equal(correctOptions.Count, result.Results.Count);
        Assert.All(result.Results, item => Assert.True(item.IsCorrect));
        Assert.All(
            result.Results,
            item => Assert.False(string.IsNullOrWhiteSpace(item.Explanation)));
        Assert.All(
            result.Results,
            item => Assert.Equal(item.SelectedOption, item.CorrectOption));
    }

    [Fact]
    public async Task Submit_WrongAnswer_ReturnsCorrectOptionAndExplanation()
    {
        var token = await RegisterAsync();
        var (quizId, correctOptions) = await GetSeededQuizAsync();

        // İlk soru bilerek yanlış cevaplanır.
        var first = correctOptions.First();
        var wrongOption = first.Value.Trim().ToUpperInvariant() == "A" ? "B" : "A";

        var answers = correctOptions
            .Select(pair => new
            {
                questionId = pair.Key,
                selectedOption = pair.Key == first.Key ? wrongOption : pair.Value
            })
            .ToList();

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/quizzes/{quizId}/submit",
            token,
            new { answers });

        response.EnsureSuccessStatusCode();

        var result = await response
            .Content.ReadFromJsonAsync<QuizSubmitResultResponse>();

        var wrong = result!.Results.Single(r => r.QuestionId == first.Key);

        Assert.False(wrong.IsCorrect);
        Assert.Equal(wrongOption, wrong.SelectedOption);
        Assert.Equal(first.Value, wrong.CorrectOption);
        Assert.False(string.IsNullOrWhiteSpace(wrong.CorrectOptionText));
        Assert.False(string.IsNullOrWhiteSpace(wrong.Explanation));
        Assert.False(string.IsNullOrWhiteSpace(wrong.Text));

        Assert.Equal(1, result.WrongAnswers);
        Assert.Equal(correctOptions.Count - 1, result.CorrectAnswers);
    }

    [Fact]
    public async Task Submit_UnansweredQuestion_IsReportedAsWrong()
    {
        var token = await RegisterAsync();
        var (quizId, correctOptions) = await GetSeededQuizAsync();

        // Yalnızca ilk soru cevaplanır.
        var first = correctOptions.First();

        var response = await SendAsync(
            HttpMethod.Post,
            $"/api/quizzes/{quizId}/submit",
            token,
            new
            {
                answers = new[]
                {
                    new { questionId = first.Key, selectedOption = first.Value }
                }
            });

        response.EnsureSuccessStatusCode();

        var result = await response
            .Content.ReadFromJsonAsync<QuizSubmitResultResponse>();

        var unanswered = result!.Results
            .Where(r => r.QuestionId != first.Key)
            .ToList();

        Assert.NotEmpty(unanswered);
        Assert.All(unanswered, item => Assert.Null(item.SelectedOption));
        Assert.All(unanswered, item => Assert.False(item.IsCorrect));
    }
}
