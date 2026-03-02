namespace Sumpooj.Domain.Entities;

/// <summary>
/// Tracks each AI generation call for rate-limiting and cost control.
/// One record per OpenAI API call.
/// </summary>
public class AIUsageRecord : BaseEntity
{
    private AIUsageRecord() { } // EF Core

    public AIUsageRecord(
        Guid companyId,
        Guid userId,
        string feature,
        string model,
        string? promptSummary)
    {
        CompanyId = companyId;
        UserId = userId;
        Feature = feature;
        Model = model;
        PromptSummary = promptSummary;
    }

    public Guid CompanyId { get; private set; }
    public Guid UserId { get; private set; }

    /// <summary>Feature key, e.g. "giftcard_background".</summary>
    public string Feature { get; private set; } = default!;

    /// <summary>Model used, e.g. "dall-e-3".</summary>
    public string Model { get; private set; } = default!;

    /// <summary>Short summary of the prompt for auditing (not the full prompt).</summary>
    public string? PromptSummary { get; private set; }
}
