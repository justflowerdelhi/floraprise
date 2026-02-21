using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Staff;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class StaffService
{
    private readonly IStaffRepository _staffRepository;

    public StaffService(IStaffRepository staffRepository)
    {
        _staffRepository = staffRepository;
    }

    public async Task<StaffDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var staff = await _staffRepository.GetByIdAsync(companyId, id);
        return staff == null ? null : MapToDto(staff);
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

    public async Task<Guid> CreateAsync(Guid companyId, CreateStaffRequest request)
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

        await _staffRepository.AddAsync(staff);
        return staff.Id;
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

    private static StaffDto MapToDto(Domain.Entities.Staff staff) => new()
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
        CreatedAtUtc = staff.CreatedAtUtc
    };
}
