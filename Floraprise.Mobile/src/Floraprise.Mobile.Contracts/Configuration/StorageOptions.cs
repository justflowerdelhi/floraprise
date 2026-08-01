namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class StorageOptions
{
    public const string SectionName = "Storage";

    public string Provider { get; set; } = "Local";

    public string ConnectionString { get; set; } = "UseDevelopmentStorage=true";

    public string ContainerName { get; set; } = "mobile";
}
