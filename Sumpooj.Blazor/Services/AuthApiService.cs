using System.Net.Http.Json;
using Microsoft.Extensions.Logging;
using Sumpooj.Blazor.Models;

namespace Sumpooj.Blazor.Services;

public class AuthApiService
{
    private readonly HttpClient _http;
    private readonly ITokenStorage _tokenStorage;
    private readonly ILogger<AuthApiService> _logger;

    public AuthApiService(
        IHttpClientFactory factory,
        ITokenStorage tokenStorage,
        ILogger<AuthApiService> logger)
    {
        _http = factory.CreateClient("Api");
        _tokenStorage = tokenStorage;
        _logger = logger;
    }

    public async Task<string?> LoginAsync(LoginRequest request)
    {
        var response = await _http.PostAsJsonAsync("api/auth/login", request);

        if (!response.IsSuccessStatusCode)
            return null;

        var result = await response.Content.ReadFromJsonAsync<LoginResponse>();
        var token = result?.AccessToken;

        if (!string.IsNullOrWhiteSpace(token))
        {
            try
            {
                // Ensure server-side in-memory token is set so JwtAuthHandler can attach it.
                await _tokenStorage.SetAsync(token);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to persist token to TokenStorage after login.");
            }
        }

        return token;
    }
}
