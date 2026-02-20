namespace Sumpooj.API.Models;

/// <summary>
/// Request payload for AI gift-card / greeting-card background generation.
/// The frontend sends the user's dropdown selections; the backend resolves
/// the mapped floral style and builds the full image-generation prompt.
/// </summary>
public class GenerateGiftCardBackgroundRequest
{
    /// <summary>Occasion key, e.g. "birthday", "wedding". Informational only.</summary>
    public string Occasion { get; set; } = default!;

    /// <summary>Color-theme key, e.g. "romantic_red", "blush_pink".</summary>
    public string Theme { get; set; } = default!;

    /// <summary>Floral-style key, e.g. "classic_roses", "vintage_peony".</summary>
    public string FloralStyle { get; set; } = default!;
}

/// <summary>
/// Response returned after generating a greeting-card background image.
/// </summary>
public class GenerateGiftCardBackgroundResponse
{
    /// <summary>URL of the generated background image (or data URI in mock mode).</summary>
    public string BackgroundImageUrl { get; set; } = default!;

    /// <summary>ISO-8601 timestamp of generation.</summary>
    public string GeneratedAt { get; set; } = default!;

    /// <summary>The prompt that was sent to the image model (returned for debugging).</summary>
    public string? Prompt { get; set; }
}
