namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class DatabaseOptions
{
    public const string SectionName = "Database";

    public string Provider { get; set; } = "SqlServer";

    public string ConnectionString { get; set; } = "Server=localhost;Database=FlorapriseMobile;Trusted_Connection=True;";

    public int CommandTimeoutSeconds { get; set; } = 30;
}
