using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.JSInterop;
using Sumpooj.Blazor.Auth;

namespace Sumpooj.Blazor.Services;

public interface ITokenStorageNotifier
{
    event Action? Ready;
    event Action? TokenChanged;
}

public class TokenStorage : ITokenStorage, ITokenStorageNotifier
{
    private readonly IJSRuntime _js;

    // Temporary in-memory token used before JS runtime is available
    private string? _inMemoryToken;

    public bool IsReady { get; private set; }

    // Events used by AuthenticationStateProvider (or other consumers)
    public event Action? Ready;
    public event Action? TokenChanged;

    public TokenStorage(
        IJSRuntime js)
    {
        _js = js;
    }

    public void MarkReady()
    {
        IsReady = true;

        // If a token was set before JS was available, persist it now
        if (!string.IsNullOrWhiteSpace(_inMemoryToken))
        {
            // Fire-and-forget persistence since callers expect MarkReady to be synchronous
            _ = PersistInMemoryTokenAsync();
        }

        // IMPORTANT: re-evaluate auth after JS becomes available
        Ready?.Invoke();
    }

    public async Task SetAsync(string token)
    {
        // If JS not ready yet, keep token in memory and notify subscribers
        if (!IsReady)
        {
            _inMemoryToken = token;
            TokenChanged?.Invoke();
            return;
        }

        _inMemoryToken = token;

        await _js.InvokeVoidAsync(
            "localStorage.setItem", "auth_token", token);

        // Notify auth change
        TokenChanged?.Invoke();
    }

    public async Task<string?> GetAsync()
    {
        // If JS not ready, return any in-memory token (may be null)
        if (!IsReady)
            return _inMemoryToken;

        // Prefer in-memory token if present (avoids a trip to JS)
        if (!string.IsNullOrWhiteSpace(_inMemoryToken))
            return _inMemoryToken;

        return await _js.InvokeAsync<string?>(
            "localStorage.getItem", "auth_token");
    }

    public async Task ClearAsync()
    {
        // Clear in-memory token regardless
        _inMemoryToken = null;

        if (!IsReady) return;

        await _js.InvokeVoidAsync(
            "localStorage.removeItem", "auth_token");

        TokenChanged?.Invoke();
    }

    private async Task PersistInMemoryTokenAsync()
    {
        if (string.IsNullOrWhiteSpace(_inMemoryToken)) return;

        try
        {
            await _js.InvokeVoidAsync(
                "localStorage.setItem", "auth_token", _inMemoryToken);

            TokenChanged?.Invoke();
        }
        catch
        {
            // Swallow - JS interop may fail in unusual cases; auth will remain using in-memory token
        }
    }
}



public interface ITokenStorage
{
    Task SetAsync(string token);
    Task<string?> GetAsync();
    Task ClearAsync();
    bool IsReady { get; }
}
