namespace Floraprise.Mobile.Contracts.Configuration;

public sealed class RedisOptions
{
    public const string SectionName = "Redis";

    public string ConnectionString { get; set; } = "localhost:6379";

    public string InstanceName { get; set; } = "Floraprise.Mobile";

    public bool AbortOnConnectFail { get; set; } = false;
}
