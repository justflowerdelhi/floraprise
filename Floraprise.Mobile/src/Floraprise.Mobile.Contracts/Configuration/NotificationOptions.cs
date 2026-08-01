namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class NotificationOptions
{
    public const string SectionName = "Notification";

    public string Provider { get; set; } = "None";

    public string HubName { get; set; } = "default";

    public bool Enabled { get; set; } = false;
}
