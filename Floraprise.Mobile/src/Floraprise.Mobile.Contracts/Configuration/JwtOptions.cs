namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "Floraprise.Mobile";

    public string Audience { get; set; } = "Floraprise.Mobile.Client";

    public string Key { get; set; } = "replace-with-a-long-secret-key";

    public int ExpiryMinutes { get; set; } = 60;

    public bool ValidateIssuer { get; set; } = true;

    public bool ValidateAudience { get; set; } = true;

    public bool ValidateLifetime { get; set; } = true;

    public bool ValidateIssuerSigningKey { get; set; } = true;
}
