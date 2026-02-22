using Microsoft.AspNetCore.Identity;
using Sumpooj.Application.Interfaces;
using Sumpooj.Infrastructure.Identity;

namespace Sumpooj.Infrastructure;

/// <summary>
/// ASP.NET Identity operations exposed to the Application layer via <see cref="IIdentityService"/>.
/// </summary>
public class IdentityService : IIdentityService
{
    private readonly UserManager<ApplicationUser> _userManager;

    public IdentityService(UserManager<ApplicationUser> userManager)
    {
        _userManager = userManager;
    }

    public async Task<bool> UserExistsAsync(string userName)
    {
        var existing = await _userManager.FindByNameAsync(userName);
        return existing != null;
    }

    public async Task<Guid> CreateUserAsync(
        string userName,
        string password,
        string? email,
        string? phoneNumber,
        Guid? companyId,
        string role)
    {
        var user = new ApplicationUser
        {
            UserName = userName,
            Email = email,
            PhoneNumber = phoneNumber,
            CompanyId = companyId,
            IsActive = true,
        };

        var createResult = await _userManager.CreateAsync(user, password);
        if (!createResult.Succeeded)
        {
            var errors = string.Join("; ", createResult.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to create identity user: {errors}");
        }

        var roleResult = await _userManager.AddToRoleAsync(user, role);
        if (!roleResult.Succeeded)
        {
            // Rollback: delete created user
            await _userManager.DeleteAsync(user);
            var errors = string.Join("; ", roleResult.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to assign role '{role}': {errors}");
        }

        return user.Id;
    }

    public async Task DeleteUserAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user != null)
        {
            await _userManager.DeleteAsync(user);
        }
    }

    public async Task<(string UserName, string Role)?> GetUserInfoAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return null;

        var roles = await _userManager.GetRolesAsync(user);
        var primaryRole = roles.FirstOrDefault() ?? "Staff";
        return (user.UserName!, primaryRole);
    }

    public async Task ResetPasswordAsync(Guid userId, string newPassword)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString())
            ?? throw new InvalidOperationException($"Identity user {userId} not found.");

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);

        var result = await _userManager.ResetPasswordAsync(user, token, newPassword);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to reset password: {errors}");
        }
    }

    public async Task DisableLoginAsync(Guid userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString())
            ?? throw new InvalidOperationException($"Identity user {userId} not found.");

        var result = await _userManager.DeleteAsync(user);
        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            throw new InvalidOperationException($"Failed to disable login: {errors}");
        }
    }
}
