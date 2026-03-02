namespace Sumpooj.Domain.Entities;

public class RefreshToken
{
    private RefreshToken() { }

    public RefreshToken(Guid userId, int expiryDays = 7)
    {
        Id = Guid.NewGuid();
        UserId = userId;
        Token = GenerateToken();
        ExpiresAtUtc = DateTime.UtcNow.AddDays(expiryDays);
        CreatedAtUtc = DateTime.UtcNow;
        IsRevoked = false;
    }

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public string Token { get; private set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime? RevokedAtUtc { get; private set; }
    public bool IsRevoked { get; private set; }
    public string? ReplacedByToken { get; private set; }

    public bool IsExpired => DateTime.UtcNow >= ExpiresAtUtc;
    public bool IsActive => !IsRevoked && !IsExpired;

    public void Revoke(string? replacedByToken = null)
    {
        IsRevoked = true;
        RevokedAtUtc = DateTime.UtcNow;
        ReplacedByToken = replacedByToken;
    }

    private static string GenerateToken()
    {
        var bytes = new byte[64];
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes);
    }
}
