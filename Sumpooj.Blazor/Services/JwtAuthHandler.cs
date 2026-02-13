using Sumpooj.Blazor.Services;
using System.Net.Http.Headers;
using Microsoft.Extensions.Logging;

public class JwtAuthHandler : DelegatingHandler
{
    private readonly ITokenStorage _tokenStorage;
    private readonly ILogger<JwtAuthHandler> _logger;

    public JwtAuthHandler(ITokenStorage tokenStorage, ILogger<JwtAuthHandler> logger)
    {
        _tokenStorage = tokenStorage;
        _logger = logger;
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        string? token = null;

        try
        {
            token = await _tokenStorage.GetAsync();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to get token from storage before sending request to {Url}", request.RequestUri);
        }

        if (!string.IsNullOrWhiteSpace(token))
        {
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", token);

            _logger.LogDebug("Added Authorization header to request {Method} {Url}", request.Method, request.RequestUri);
        }
        else
        {
            _logger.LogDebug("No token available when sending request {Method} {Url}", request.Method, request.RequestUri);
        }

        return await base.SendAsync(request, cancellationToken);
    }
}
