namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class LicenseOptions
{
    public const string SectionName = "License";

    public bool Enabled { get; set; } = true;

    public string ValidationService { get; set; } = "Default";

    public int CheckIntervalMinutes { get; set; } = 60;
}
