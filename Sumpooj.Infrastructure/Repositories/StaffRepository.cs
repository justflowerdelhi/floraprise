using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Staff;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class StaffRepository : IStaffRepository
{
    private readonly SumpoojDbContext _db;

    public StaffRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Domain.Entities.Staff?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Staff
            .FirstOrDefaultAsync(s => s.CompanyId == companyId && s.Id == id);
    }

    public async Task<PagedResult<StaffListDto>> SearchAsync(Guid companyId, StaffSearchRequest request)
    {
        var query = _db.Staff.Where(s => s.CompanyId == companyId);

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.ToLower();
            query = query.Where(s =>
                s.Name.ToLower().Contains(q) ||
                (s.Email != null && s.Email.ToLower().Contains(q)) ||
                (s.Phone != null && s.Phone.Contains(q)));
        }

        if (!string.IsNullOrWhiteSpace(request.Role) && Enum.TryParse<StaffRole>(request.Role, true, out var role))
        {
            query = query.Where(s => s.Role == role);
        }

        if (request.IsActive.HasValue)
        {
            query = query.Where(s => s.IsActive == request.IsActive.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(s => s.Name)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(s => new StaffListDto
            {
                Id = s.Id,
                Name = s.Name,
                Role = s.Role.ToString(),
                Email = s.Email,
                Phone = s.Phone,
                IsActive = s.IsActive,
                CommissionType = s.CommissionType != null ? s.CommissionType.ToString() : null,
                CommissionRate = s.CommissionRate
            })
            .ToListAsync();

        return new PagedResult<StaffListDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<StaffListDto>> GetAllActiveAsync(Guid companyId)
    {
        return await _db.Staff
            .Where(s => s.CompanyId == companyId && s.IsActive)
            .OrderBy(s => s.Name)
            .Select(s => new StaffListDto
            {
                Id = s.Id,
                Name = s.Name,
                Role = s.Role.ToString(),
                Email = s.Email,
                Phone = s.Phone,
                IsActive = s.IsActive,
                CommissionType = s.CommissionType != null ? s.CommissionType.ToString() : null,
                CommissionRate = s.CommissionRate
            })
            .ToListAsync();
    }

    public async Task<List<StaffListDto>> GetByRoleAsync(Guid companyId, string role)
    {
        if (!Enum.TryParse<StaffRole>(role, true, out var staffRole))
            return new List<StaffListDto>();

        return await _db.Staff
            .Where(s => s.CompanyId == companyId && s.IsActive && s.Role == staffRole)
            .OrderBy(s => s.Name)
            .Select(s => new StaffListDto
            {
                Id = s.Id,
                Name = s.Name,
                Role = s.Role.ToString(),
                Email = s.Email,
                Phone = s.Phone,
                IsActive = s.IsActive,
                CommissionType = s.CommissionType != null ? s.CommissionType.ToString() : null,
                CommissionRate = s.CommissionRate
            })
            .ToListAsync();
    }

    public async Task AddAsync(Domain.Entities.Staff staff)
    {
        await _db.Staff.AddAsync(staff);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Domain.Entities.Staff staff)
    {
        _db.Staff.Update(staff);
        await _db.SaveChangesAsync();
    }
}
