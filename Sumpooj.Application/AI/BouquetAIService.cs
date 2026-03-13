using OpenAI;
using OpenAI.Chat;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace Sumpooj.Application.AI;

// ─── DTOs ───────────────────────────────────────────────────

public class BouquetAnalysisResult
{
    public string Style { get; set; } = string.Empty;
    public string Shape { get; set; } = string.Empty;
    public string Height { get; set; } = string.Empty;
    public List<FlowerDetection> Flowers { get; set; } = new();
}

public class FlowerDetection
{
    public string Flower { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
    public int StemCount { get; set; }
}

public class SaveBouquetRecipeRequest
{
    public string Name { get; set; } = default!;
    public string? Style { get; set; }
    public string? Shape { get; set; }
    public string? Height { get; set; }
    public List<BouquetComponent> Components { get; set; } = new();
}

public class BouquetComponent
{
    public string Flower { get; set; } = default!;
    public string? Color { get; set; }
    public int Stems { get; set; }
}

public class AICreateProductRequest
{
    public string Name { get; set; } = default!;
    public decimal Price { get; set; }
    public decimal Cost { get; set; }
    public List<BouquetComponent>? Components { get; set; }
    public string? Image { get; set; }
}

// ─── Service ────────────────────────────────────────────────

public partial class BouquetAIService
{
    private const string Feature = "bouquet_scan";
    private const string Model = "gpt-4o-mini";

    private readonly OpenAISettings _settings;
    private readonly IAIUsageRepository _usageRepo;

    public BouquetAIService(OpenAISettings settings, IAIUsageRepository usageRepo)
    {
        _settings = settings;
        _usageRepo = usageRepo;
    }

    /// <summary>
    /// Analyze a bouquet image using GPT-4o-mini vision.
    /// Returns detected flowers, style, shape, and height.
    /// </summary>
    public async Task<BouquetAnalysisResult> AnalyzeAsync(
        Guid companyId, Guid userId, byte[] imageBytes, string contentType)
    {
        if (string.IsNullOrWhiteSpace(_settings.ApiKey))
            throw new InvalidOperationException(
                "OpenAI API key is not configured. Add OpenAI:ApiKey to appsettings.json.");

        // Enforce limits
        var dailyUsed = await _usageRepo.GetDailyCountByUserAsync(userId, Feature);
        if (_settings.DailyLimitPerUser > 0 && dailyUsed >= _settings.DailyLimitPerUser)
            throw new AIUsageLimitException(
                $"Daily limit reached ({_settings.DailyLimitPerUser} per user). Try again tomorrow.");

        var monthlyUsed = await _usageRepo.GetMonthlyCountByCompanyAsync(companyId, Feature);
        if (_settings.MonthlyLimitPerCompany > 0 && monthlyUsed >= _settings.MonthlyLimitPerCompany)
            throw new AIUsageLimitException(
                $"Monthly limit reached ({_settings.MonthlyLimitPerCompany} per company). Resets next month.");

        // Build the vision request
        var base64 = Convert.ToBase64String(imageBytes);
        var dataUri = $"data:{contentType};base64,{base64}";

        var client = new OpenAIClient(_settings.ApiKey);
        var chatClient = client.GetChatClient(Model);

        var messages = new List<ChatMessage>
        {
            new UserChatMessage(
                ChatMessageContentPart.CreateTextPart(AnalysisPrompt),
                ChatMessageContentPart.CreateImagePart(new Uri(dataUri))
            )
        };

        var completion = await chatClient.CompleteChatAsync(messages);
        var text = completion.Value.Content[0].Text ?? "{}";

        // Record usage
        var record = new AIUsageRecord(companyId, userId, Feature, Model, "bouquet_analysis");
        await _usageRepo.AddAsync(record);

        // Parse JSON from response (may contain markdown fences)
        return ParseAnalysisResult(text);
    }

    private static BouquetAnalysisResult ParseAnalysisResult(string text)
    {
        // Strip markdown code fences
        text = text.Replace("```json", "").Replace("```", "").Trim();

        var match = JsonPattern().Match(text);
        if (!match.Success)
            return new BouquetAnalysisResult();

        try
        {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var raw = JsonSerializer.Deserialize<JsonElement>(match.Value, options);

            var result = new BouquetAnalysisResult
            {
                Style = raw.TryGetProperty("style", out var s) ? s.GetString() ?? "" : "",
                Shape = raw.TryGetProperty("shape", out var sh) ? sh.GetString() ?? "" : "",
                Height = raw.TryGetProperty("height", out var h) ? h.GetString() ?? "" : "",
            };

            if (raw.TryGetProperty("flowers", out var flowers) && flowers.ValueKind == JsonValueKind.Array)
            {
                foreach (var f in flowers.EnumerateArray())
                {
                    result.Flowers.Add(new FlowerDetection
                    {
                        Flower = f.TryGetProperty("flower", out var fn) ? fn.GetString() ?? "" : "",
                        Color = f.TryGetProperty("color", out var c) ? c.GetString() ?? "" : "",
                        StemCount = f.TryGetProperty("stem_count", out var sc) ? sc.GetInt32() : 0,
                    });
                }
            }

            return result;
        }
        catch
        {
            return new BouquetAnalysisResult();
        }
    }

    private const string AnalysisPrompt = """
        You are a professional florist.

        Analyze the bouquet image and identify:

        1. Flowers and stem counts
        2. Bouquet style (hand tied, arrangement, basket etc)
        3. Shape (round, heart, oval, one sided, cascade etc)
        4. Height style (compact, medium, tall)

        Return ONLY JSON in this format:

        {
         "style":"Floral Arrangement",
         "shape":"Heart",
         "height":"Compact",
         "flowers":[
           {"flower":"Rose","color":"Red","stem_count":50}
         ]
        }
        """;

    [GeneratedRegex(@"\{.*\}", RegexOptions.Singleline)]
    private static partial Regex JsonPattern();
}
