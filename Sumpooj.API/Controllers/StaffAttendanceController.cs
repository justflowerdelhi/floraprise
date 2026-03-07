using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

public class StaffAttendanceDto
{
    public Guid Id { get; set; }
    public Guid StaffId { get; set; }
    public string StaffName { get; set; } = default!;
    public string StaffRole { get; set; } = default!;
    public string? CheckIn { get; set; }
    public string? CheckOut { get; set; }
    public string Status { get; set; } = "Absent";
}

[ApiController]
[Route("api/staff/attendance")]
[Authorize(Policy = "CompanyOnly")]
public class StaffAttendanceController : ControllerBase
{
    private readonly SumpoojDbContext _db;
    private readonly ITenantContext _tenantContext;

    public StaffAttendanceController(SumpoojDbContext db, ITenantContext tenantContext)
    {
        _db = db;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    [HttpGet("today")]
    public async Task<IActionResult> GetToday()
    {
        var cid = CompanyId;
        var todayUtc = DateTime.UtcNow.Date;

        var staff = await _db.Staff
            .Where(s => s.CompanyId == cid && s.IsActive)
            .OrderBy(s => s.Name).ToListAsync();

        var todayRecords = await _db.StaffAttendanceRecords
            .Where(r => r.CompanyId == cid && r.CheckInUtc >= todayUtc)
            .ToListAsync();

        var result = staff.Select(s =>
        {
            var record = todayRecords.FirstOrDefault(r => r.StaffId == s.Id);
            return new StaffAttendanceDto
            {
                Id = record?.Id ?? Guid.Empty,
                StaffId = s.Id,
                StaffName = s.Name,
                StaffRole = s.Role.ToString(),
                CheckIn = record?.CheckInUtc.ToString("HH:mm"),
                CheckOut = record?.CheckOutUtc?.ToString("HH:mm"),
                Status = record == null ? "Absent"
                    : record.CheckOutUtc.HasValue ? "Completed" : "Working",
            };
        }).ToList();

        return Ok(result);
    }

    [HttpPost("{staffId:guid}/check-in")]
    public async Task<IActionResult> CheckIn(Guid staffId)
    {
        var cid = CompanyId;
        var staff = await _db.Staff.FirstOrDefaultAsync(s => s.CompanyId == cid && s.Id == staffId);
        if (staff == null) return NotFound();

        var record = new StaffAttendanceRecord(cid, staffId, DateTime.UtcNow);
        _db.StaffAttendanceRecords.Add(record);
        await _db.SaveChangesAsync();

        return Ok(new StaffAttendanceDto
        {
            Id = record.Id, StaffId = staffId,
            StaffName = staff.Name, StaffRole = staff.Role.ToString(),
            CheckIn = record.CheckInUtc.ToString("HH:mm"),
            Status = "Working",
        });
    }

    [HttpPost("{recordId:guid}/check-out")]
    public async Task<IActionResult> CheckOut(Guid recordId)
    {
        var record = await _db.StaffAttendanceRecords
            .FirstOrDefaultAsync(r => r.CompanyId == CompanyId && r.Id == recordId);
        if (record == null) return NotFound();

        record.CheckOut();
        await _db.SaveChangesAsync();

        var staff = await _db.Staff.FindAsync(record.StaffId);
        return Ok(new StaffAttendanceDto
        {
            Id = record.Id, StaffId = record.StaffId,
            StaffName = staff?.Name ?? "", StaffRole = staff?.Role.ToString() ?? "",
            CheckIn = record.CheckInUtc.ToString("HH:mm"),
            CheckOut = record.CheckOutUtc?.ToString("HH:mm"),
            Status = "Completed",
        });
    }
}
