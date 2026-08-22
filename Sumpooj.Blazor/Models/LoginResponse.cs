using System.Text.Json.Serialization;

namespace Sumpooj.Blazor.Models;

public class LoginResponse
{
    [JsonPropertyName("access_token")]
    public string AccessToken { get; set; } = "";

    [JsonPropertyName("refresh_token")]
    public string RefreshToken { get; set; } = "";

    [JsonPropertyName("user")]
    public object? User { get; set; }

    [JsonPropertyName("tenant")]
    public object? Tenant { get; set; }
}
