namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class MobileOptions
{
    public const string SectionName = "Mobile";

    public string ServiceName { get; set; } = "Floraprise.Mobile";

    public string Version { get; set; } = "1.0.0";
}
