using OpenAI;
using OpenAI.Images;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.AI;

// ─── Config (bound from appsettings.json → "OpenAI") ───────

public class OpenAISettings
{
    public string? ApiKey { get; set; }

    /// <summary>Max image generations per user per day. 0 = unlimited.</summary>
    public int DailyLimitPerUser { get; set; } = 10;

    /// <summary>Max image generations per company per calendar month. 0 = unlimited.</summary>
    public int MonthlyLimitPerCompany { get; set; } = 100;
}

// ─── Request / Response DTOs ────────────────────────────────

public class GiftCardBackgroundRequest
{
    public string Occasion { get; set; } = default!;
    public string Theme { get; set; } = default!;
    public string FloralStyle { get; set; } = default!;
}

public class GiftCardBackgroundResponse
{
    public string ImageUrl { get; set; } = default!;
    public string Prompt { get; set; } = default!;
    public AIUsageInfo Usage { get; set; } = default!;
}

public class AIUsageInfo
{
    public int DailyUsed { get; set; }
    public int DailyLimit { get; set; }
    public int DailyRemaining { get; set; }
    public int MonthlyUsed { get; set; }
    public int MonthlyLimit { get; set; }
    public int MonthlyRemaining { get; set; }
}

// ─── Service ────────────────────────────────────────────────

public class GiftCardAIService
{
    private const string Feature = "giftcard_background";
    private const string Model = "dall-e-3";

    private readonly OpenAISettings _settings;
    private readonly IAIUsageRepository _usageRepo;

    public GiftCardAIService(OpenAISettings settings, IAIUsageRepository usageRepo)
    {
        _settings = settings;
        _usageRepo = usageRepo;
    }

    /// <summary>
    /// Get current usage counters without generating an image.
    /// </summary>
    public async Task<AIUsageInfo> GetUsageAsync(Guid companyId, Guid userId)
    {
        var dailyUsed = await _usageRepo.GetDailyCountByUserAsync(userId, Feature);
        var monthlyUsed = await _usageRepo.GetMonthlyCountByCompanyAsync(companyId, Feature);

        return BuildUsageInfo(dailyUsed, monthlyUsed);
    }

    /// <summary>
    /// Generate a gift card background image via DALL-E 3, enforcing usage limits.
    /// </summary>
    public async Task<GiftCardBackgroundResponse> GenerateBackgroundAsync(
        Guid companyId,
        Guid userId,
        GiftCardBackgroundRequest request)
    {
        if (string.IsNullOrWhiteSpace(_settings.ApiKey))
            throw new InvalidOperationException(
                "OpenAI API key is not configured. Add OpenAI:ApiKey to appsettings.json.");

        // ── Enforce limits ──────────────────────────────
        var dailyUsed = await _usageRepo.GetDailyCountByUserAsync(userId, Feature);
        if (_settings.DailyLimitPerUser > 0 && dailyUsed >= _settings.DailyLimitPerUser)
            throw new AIUsageLimitException(
                $"Daily limit reached ({_settings.DailyLimitPerUser} per user). Try again tomorrow.");

        var monthlyUsed = await _usageRepo.GetMonthlyCountByCompanyAsync(companyId, Feature);
        if (_settings.MonthlyLimitPerCompany > 0 && monthlyUsed >= _settings.MonthlyLimitPerCompany)
            throw new AIUsageLimitException(
                $"Monthly limit reached ({_settings.MonthlyLimitPerCompany} per company). Resets next month.");

        // ── Generate image ──────────────────────────────
        var prompt = BuildPrompt(request);

        var client = new OpenAIClient(_settings.ApiKey);
        var imageClient = client.GetImageClient(Model);

        var options = new ImageGenerationOptions
        {
            Quality = GeneratedImageQuality.Standard,
            Size = GeneratedImageSize.W1024xH1024,
            ResponseFormat = GeneratedImageFormat.Uri,
        };

        var result = await imageClient.GenerateImageAsync(prompt, options);
        var imageUrl = result.Value.ImageUri?.ToString()
            ?? throw new InvalidOperationException("Image generation returned no URL.");

        // ── Record usage ────────────────────────────────
        var promptSummary = $"{request.Occasion}/{request.Theme}/{request.FloralStyle}";
        var record = new AIUsageRecord(companyId, userId, Feature, Model, promptSummary);
        await _usageRepo.AddAsync(record);

        return new GiftCardBackgroundResponse
        {
            ImageUrl = imageUrl,
            Prompt = prompt,
            Usage = BuildUsageInfo(dailyUsed + 1, monthlyUsed + 1),
        };
    }

    private AIUsageInfo BuildUsageInfo(int dailyUsed, int monthlyUsed)
    {
        var dailyLimit = _settings.DailyLimitPerUser;
        var monthlyLimit = _settings.MonthlyLimitPerCompany;

        return new AIUsageInfo
        {
            DailyUsed = dailyUsed,
            DailyLimit = dailyLimit,
            DailyRemaining = dailyLimit > 0 ? Math.Max(0, dailyLimit - dailyUsed) : int.MaxValue,
            MonthlyUsed = monthlyUsed,
            MonthlyLimit = monthlyLimit,
            MonthlyRemaining = monthlyLimit > 0 ? Math.Max(0, monthlyLimit - monthlyUsed) : int.MaxValue,
        };
    }

    private static string BuildPrompt(GiftCardBackgroundRequest request)
    {
        return $"Create a beautiful, elegant gift card background image for a florist shop. " +
               $"Occasion: {request.Occasion}. " +
               $"Color theme: {request.Theme}. " +
               $"Floral style: {request.FloralStyle}. " +
               $"The image should be soft, artistic, and suitable as a gift card background. " +
               $"No text or letters in the image. Photorealistic floral arrangement with bokeh background.";
    }
}

/// <summary>
/// Thrown when a user/company exceeds their AI generation quota.
/// </summary>
public class AIUsageLimitException : Exception
{
    public AIUsageLimitException(string message) : base(message) { }
}
