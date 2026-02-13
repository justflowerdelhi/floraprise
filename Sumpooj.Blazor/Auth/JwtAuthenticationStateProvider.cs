using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using Sumpooj.Blazor.Services;

namespace Sumpooj.Blazor.Auth;

public class JwtAuthenticationStateProvider : AuthenticationStateProvider
{
    private readonly ITokenStorage _tokenStorage;

    public JwtAuthenticationStateProvider(ITokenStorage tokenStorage, ITokenStorageNotifier notifier)
    {
        _tokenStorage = tokenStorage;

        // Subscribe to storage events via notifier
        notifier.Ready += () => NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
        notifier.TokenChanged += () => NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
    }

    public override async Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        // 🔥 JS not ready yet → anonymous
        if (!_tokenStorage.IsReady)
            return Anonymous();

        var token = await _tokenStorage.GetAsync();

        if (string.IsNullOrWhiteSpace(token))
            return Anonymous();

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.ReadJwtToken(token);

        var identity = new ClaimsIdentity(
            jwt.Claims,
            authenticationType: "jwt");

        return new AuthenticationState(
            new ClaimsPrincipal(identity));
    }

    public void MarkUserAsAuthenticated()
    {
        NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
    }

    public void MarkUserAsLoggedOut()
    {
        NotifyAuthenticationStateChanged(
            Task.FromResult(Anonymous()));
    }

    // Compatibility helpers used by UI code
    public void NotifyUserAuthentication()
        => MarkUserAsAuthenticated();

    public void NotifyUserLogout()
        => MarkUserAsLoggedOut();

    private static AuthenticationState Anonymous()
        => new(new ClaimsPrincipal(new ClaimsIdentity()));
}
