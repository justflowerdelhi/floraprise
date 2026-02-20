using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.API.Models;
using Sumpooj.Application.Authorization;

namespace Sumpooj.API.Controllers;

/// <summary>
/// AI-powered greeting-card background generation.
/// Builds a botanically-precise image-generation prompt from the user's
/// occasion / theme / floral-style selections and forwards it to the
/// configured image-generation backend (DALL-E, Stable Diffusion, etc.).
/// </summary>
[ApiController]
[Route("api/ai/giftcard")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class GiftCardController : ControllerBase
{
    private readonly ILogger<GiftCardController> _logger;

    public GiftCardController(ILogger<GiftCardController> logger)
    {
        _logger = logger;
    }

    // ─── Mapped Floral Style Descriptions ───────────────────
    // Botanically-specific descriptions that anchor the image model to the
    // correct flower species and prevent generic substitutions.

    private static readonly Dictionary<string, string> MappedFloralStyles = new(StringComparer.OrdinalIgnoreCase)
    {
        ["classic_roses"]     = "lush red and pink roses with layered velvety petals, rosebuds, and dark green foliage",
        ["wildflower_meadow"] = "daisies, cornflowers, poppies, Queen Anne's lace, and wild grasses in a natural meadow arrangement",
        ["tropical_paradise"] = "hibiscus, plumeria, bird of paradise, and tropical palm leaves with vivid saturated colors",
        ["garden_english"]    = "cottage garden mix of David Austin roses, foxgloves, delphiniums, sweet peas, and lavender sprigs",
        ["minimal_botanical"] = "delicate eucalyptus branches, olive leaves, and fine fern fronds in a clean minimalist arrangement",
        ["japanese_ikebana"]  = "cherry blossoms (sakura), chrysanthemums, and bamboo in elegant asymmetric ikebana composition",
        ["vintage_peony"]     = "full-bloom peonies in blush, ivory, and dusty rose with soft ruffled petals and vintage botanical detail",
        ["succulent_modern"]  = "echeveria rosettes, aloe, and jade succulents with thick geometric leaves in muted sage and dusty tones",
        ["sunflower_rustic"]  = "large golden sunflowers with brown centers, wheat stalks, dried grasses, and burlap-textured rustic elements",
        ["orchid_luxury"]     = "phalaenopsis and cymbidium orchids with arching stems, aerial roots, and glossy tropical leaves",
    };

    // ─── Theme Display Labels ───────────────────────────────

    private static readonly Dictionary<string, string> ThemeLabels = new(StringComparer.OrdinalIgnoreCase)
    {
        ["romantic_red"]       = "Romantic Red",
        ["blush_pink"]         = "Blush Pink",
        ["lavender_dream"]     = "Lavender Dream",
        ["golden_sunset"]      = "Golden Sunset",
        ["ocean_blue"]         = "Ocean Blue",
        ["sage_green"]         = "Sage Green",
        ["ivory_white"]        = "Ivory & White",
        ["peach_coral"]        = "Peach Coral",
        ["midnight_navy"]      = "Midnight Navy",
        ["earthy_terracotta"]  = "Earthy Terracotta",
    };

    /// <summary>
    /// Generate a premium 5×7 greeting-card background image.
    /// </summary>
    [HttpPost("background")]
    public async Task<IActionResult> GenerateBackground([FromBody] GenerateGiftCardBackgroundRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.FloralStyle) || string.IsNullOrWhiteSpace(request.Theme))
            return BadRequest(new { error = "FloralStyle and Theme are required." });

        // Resolve the botanically-precise floral description
        var floralStyle = MappedFloralStyles.GetValueOrDefault(request.FloralStyle, request.FloralStyle);

        // Resolve the theme display label
        var theme = ThemeLabels.GetValueOrDefault(request.Theme, request.Theme);

        // Build the image-generation prompt
        var prompt = $@"
Create a premium vertical 5x7 greeting card design.

The primary floral composition must prominently feature:
{floralStyle}

The selected flower type must dominate the design.
Do not substitute with generic mixed flowers.

Color theme:
{theme}

Design rules:
- Floral frame around edges using {floralStyle}.
- Clear empty center space.
- Luxury greeting card layout.
- High detail botanical realism.
- No text.
- No watermark.
- Vertical orientation.
".Trim();

        _logger.LogInformation("Gift card prompt built for style={Style}, theme={Theme}",
            request.FloralStyle, request.Theme);

        // ─── TODO: Forward `prompt` to your image-generation service ────
        // e.g. OpenAI DALL-E, Stability AI, Replicate, etc.
        //
        // var imageUrl = await _imageService.GenerateAsync(prompt, width: 1024, height: 1434);
        //
        // For now, return the prompt so the frontend can verify the template:

        var response = new GenerateGiftCardBackgroundResponse
        {
            BackgroundImageUrl = "", // Replace with actual generated image URL
            GeneratedAt = DateTime.UtcNow.ToString("o"),
            Prompt = prompt,
        };

        return Ok(response);
    }
}
