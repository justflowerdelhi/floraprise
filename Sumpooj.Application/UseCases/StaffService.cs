using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Staff;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class StaffService
{
    private readonly IStaffRepository _staffRepository;
    private readonly IIdentityService? _identityService;

    public StaffService(IStaffRepository staffRepository, IIdentityService? identityService = null)
    {
        _staffRepository = staffRepository;
        _identityService = identityService;
    }

    public async Task<StaffDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var staff = await _staffRepository.GetByIdAsync(companyId, id);
        return staff == null ? null : await MapToDtoWithIdentityAsync(staff);
    }

    public async Task<PagedResult<StaffListDto>> SearchAsync(Guid companyId, StaffSearchRequest request)
    {
        return await _staffRepository.SearchAsync(companyId, request);
    }

    public async Task<List<StaffListDto>> GetAllActiveAsync(Guid companyId)
    {
        return await _staffRepository.GetAllActiveAsync(companyId);
    }

    public async Task<List<StaffListDto>> GetByRoleAsync(Guid companyId, string role)
    {
        return await _staffRepository.GetByRoleAsync(companyId, role);
    }

    public async Task<List<StaffListDto>> GetAvailableDriversAsync(Guid companyId)
    {
        return await _staffRepository.GetAvailableDriversAsync(companyId);
    }

    public async Task<CreateStaffResult> CreateAsync(Guid companyId, CreateStaffRequest request)
    {
        var role = Enum.TryParse<StaffRole>(request.Role, true, out var r) ? r : StaffRole.Staff;
        
        var staff = new Domain.Entities.Staff(
            companyId,
            request.Name,
            role,
            request.Email,
            request.Phone,
            null);

        if (request.CommissionType != null)
        {
            var commType = Enum.TryParse<CommissionType>(request.CommissionType, true, out var ct) ? ct : (CommissionType?)null;
            staff.SetCommission(commType, request.CommissionRate);
        }

        if (request.HourlyRate.HasValue)
        {
            staff.SetHourlyRate(request.HourlyRate);
        }

        if (request.PrimaryLocationId.HasValue)
        {
            staff.AssignLocation(request.PrimaryLocationId);
        }

        if (!request.IsActive)
        {
            staff.Deactivate();
        }

        // ── Optional login access ───────────────────────────
        Guid? identityUserId = null;

        if (request.EnableLogin)
        {
            if (_identityService == null)
                throw new InvalidOperationException("Identity service is not available.");

            if (string.IsNullOrWhiteSpace(request.LoginIdentifier))
                throw new ArgumentException("LoginIdentifier (email or phone) is required when EnableLogin is true.");

            if (string.IsNullOrWhiteSpace(request.LoginRole))
                throw new ArgumentException("LoginRole is required when EnableLogin is true.");

            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
                throw new ArgumentException("Password is required and must be at least 6 characters when EnableLogin is true.");

            // Check for duplicate username
            if (await _identityService.UserExistsAsync(request.LoginIdentifier))
                throw new InvalidOperationException($"A user with identifier '{request.LoginIdentifier}' already exists.");

            // Create Identity user + assign role
            var isEmail = request.LoginIdentifier.Contains('@');
            var userId = await _identityService.CreateUserAsync(
                userName: request.LoginIdentifier,
                password: request.Password,
                email: isEmail ? request.LoginIdentifier : null,
                phoneNumber: request.LoginIdentifier,
                companyId: companyId,
                role: request.LoginRole);

            identityUserId = userId;

            // Link Staff → Identity user
            staff.LinkIdentityUser(userId);
        }

        // ── Persist staff ───────────────────────────────────
        try
        {
            await _staffRepository.AddAsync(staff);
        }
        catch
        {
            // Rollback: if identity user was created but staff persistence failed, delete the identity user
            if (identityUserId.HasValue && _identityService != null)
            {
                await _identityService.DeleteUserAsync(identityUserId.Value);
            }
            throw;
        }

        return new CreateStaffResult
        {
            StaffId = staff.Id,
        };
    }

    public async Task UpdateAsync(Guid companyId, Guid id, UpdateStaffRequest request)
    {
        var staff = await _staffRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Staff not found");

        if (request.Name != null || request.Email != null || request.Phone != null)
        {
            staff.UpdateDetails(
                request.Name ?? staff.Name,
                request.Email ?? staff.Email,
                request.Phone ?? staff.Phone);
        }

        if (request.Role != null && Enum.TryParse<StaffRole>(request.Role, true, out var role))
        {
            staff.SetRole(role);
        }

        if (request.CommissionType != null || request.CommissionRate != null)
        {
            var commType = request.CommissionType != null 
                ? Enum.TryParse<CommissionType>(request.CommissionType, true, out var ct) ? ct : (CommissionType?)null
                : staff.CommissionType;
            staff.SetCommission(commType, request.CommissionRate ?? staff.CommissionRate);
        }

        if (request.HourlyRate != null)
        {
            staff.SetHourlyRate(request.HourlyRate);
        }

        if (request.PrimaryLocationId != null)
        {
            staff.AssignLocation(request.PrimaryLocationId);
        }

        if (request.IsActive.HasValue)
        {
            if (request.IsActive.Value)
                staff.Activate();
            else
                staff.Deactivate();
        }

        await _staffRepository.UpdateAsync(staff);
    }

    public async Task DeactivateAsync(Guid companyId, Guid id)
    {
        var staff = await _staffRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Staff not found");

        staff.Deactivate();
        await _staffRepository.UpdateAsync(staff);
    }

    // ── Login management (Edit mode) ─────────────────────────────

    /// <summary>Enable login for an existing staff member who does not yet have an identity user.</summary>
    public async Task EnableLoginAsync(Guid companyId, Guid staffId, EnableLoginRequest request)
    {
        if (_identityService == null)
            throw new InvalidOperationException("Identity service is not available.");

        var staff = await _staffRepository.GetByIdAsync(companyId, staffId)
            ?? throw new KeyNotFoundException("Staff not found.");

        if (staff.IdentityUserId.HasValue)
            throw new InvalidOperationException("This staff member already has login access.");

        if (string.IsNullOrWhiteSpace(request.LoginIdentifier))
            throw new ArgumentException("LoginIdentifier is required.");
        if (string.IsNullOrWhiteSpace(request.LoginRole))
            throw new ArgumentException("LoginRole is required.");
        if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            throw new ArgumentException("Password is required and must be at least 6 characters.");

        if (await _identityService.UserExistsAsync(request.LoginIdentifier))
            throw new InvalidOperationException($"A user with identifier '{request.LoginIdentifier}' already exists.");

        var isEmail = request.LoginIdentifier.Contains('@');
        var userId = await _identityService.CreateUserAsync(
            userName: request.LoginIdentifier,
            password: request.Password,
            email: isEmail ? request.LoginIdentifier : null,
            phoneNumber: request.LoginIdentifier,
            companyId: companyId,
            role: request.LoginRole);

        staff.LinkIdentityUser(userId);

        try
        {
            await _staffRepository.UpdateAsync(staff);
        }
        catch
        {
            await _identityService.DeleteUserAsync(userId);
            throw;
        }
    }

    /// <summary>Reset the password for a staff member's identity user.</summary>
    public async Task ResetPasswordAsync(Guid companyId, Guid staffId, string newPassword)
    {
        if (_identityService == null)
            throw new InvalidOperationException("Identity service is not available.");

        if (string.IsNullOrWhiteSpace(newPassword) || newPassword.Length < 6)
            throw new ArgumentException("Password is required and must be at least 6 characters.");

        var staff = await _staffRepository.GetByIdAsync(companyId, staffId)
            ?? throw new KeyNotFoundException("Staff not found.");

        if (!staff.IdentityUserId.HasValue)
            throw new InvalidOperationException("This staff member does not have login access.");

        await _identityService.ResetPasswordAsync(staff.IdentityUserId.Value, newPassword);
    }

    /// <summary>Disable login for a staff member by deleting their identity user.</summary>
    public async Task DisableLoginAsync(Guid companyId, Guid staffId)
    {
        if (_identityService == null)
            throw new InvalidOperationException("Identity service is not available.");

        var staff = await _staffRepository.GetByIdAsync(companyId, staffId)
            ?? throw new KeyNotFoundException("Staff not found.");

        if (!staff.IdentityUserId.HasValue)
            throw new InvalidOperationException("This staff member does not have login access.");

        await _identityService.DisableLoginAsync(staff.IdentityUserId.Value);

        staff.UnlinkIdentityUser();
        await _staffRepository.UpdateAsync(staff);
    }

    // ── Mapping ──────────────────────────────────────────────────

    private StaffDto MapToDto(Domain.Entities.Staff staff) => new()
    {
        Id = staff.Id,
        Name = staff.Name,
        Role = staff.Role.ToString(),
        Email = staff.Email,
        Phone = staff.Phone,
        IsActive = staff.IsActive,
        CommissionType = staff.CommissionType?.ToString(),
        CommissionRate = staff.CommissionRate,
        HourlyRate = staff.HourlyRate,
        PrimaryLocationId = staff.PrimaryLocationId,
        UserId = staff.UserId,
        CreatedAtUtc = staff.CreatedAtUtc,
        IdentityUserId = staff.IdentityUserId,
    };

    /// <summary>Populate identity fields that require an async call to the identity service.</summary>
    public async Task<StaffDto> MapToDtoWithIdentityAsync(Domain.Entities.Staff staff)
    {
        var dto = MapToDto(staff);

        if (staff.IdentityUserId.HasValue && _identityService != null)
        {
            var info = await _identityService.GetUserInfoAsync(staff.IdentityUserId.Value);
            if (info.HasValue)
            {
                dto.LoginIdentifier = info.Value.UserName;
                dto.LoginRole = info.Value.Role;
            }
        }

        return dto;
    }
}
