namespace Sumpooj.Application.Interfaces;

/// <summary>
/// Abstraction over ASP.NET Identity operations.
/// Implemented in Infrastructure; consumed by Application services.
/// </summary>
public interface IIdentityService
{
    /// <summary>Check whether a user with the given username already exists.</summary>
    Task<bool> UserExistsAsync(string userName);

    /// <summary>
    /// Create a new Identity user with the given password and assign a role.
    /// Returns the new user's ID on success.
    /// Throws <see cref="InvalidOperationException"/> on failure (with Identity error details).
    /// </summary>
    Task<Guid> CreateUserAsync(
        string userName,
        string password,
        string? email,
        string? phoneNumber,
        Guid? companyId,
        string role);

    /// <summary>Delete a user by ID. Used for rollback when staff creation fails after identity user was created.</summary>
    Task DeleteUserAsync(Guid userId);

    /// <summary>Get the username and primary role for an identity user. Returns null if not found.</summary>
    Task<(string UserName, string Role)?> GetUserInfoAsync(Guid userId);

    /// <summary>Reset the user's password to the provided new password.</summary>
    Task ResetPasswordAsync(Guid userId, string newPassword);

    /// <summary>Delete the identity user (disable login). Throws if not found.</summary>
    Task DisableLoginAsync(Guid userId);
}
