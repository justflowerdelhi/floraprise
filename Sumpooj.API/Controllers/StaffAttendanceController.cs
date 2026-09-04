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
    public string AttendanceDate { get; set; } = default!;
    public int OvertimeHours { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public DateTime? UpdatedAtUtc { get; set; }
}

public class SaveStaffAttendanceRequest
{
    public Guid StaffId { get; set; }
    public DateTime AttendanceDate { get; set; }
    public string Status { get; set; } = "NotMarked";
    public DateTime? CheckIn { get; set; }
    public DateTime? CheckOut { get; set; }
    public int OvertimeHours { get; set; }
    public string? Notes { get; set; }
}

public class StaffAttendanceSummaryDto
{
    public int Present { get; set; }
    public int Absent { get; set; }
    public int Leave { get; set; }
    public int HalfDay { get; set; }
    public int NotMarked { get; set; }
    public int TotalOvertimeHours { get; set; }
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

    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] DateTime? date, [FromQuery] Guid? staffId,
        [FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        var query = _db.StaffAttendanceRecords
            .Where(r => r.CompanyId == CompanyId);
        if (date.HasValue)
        {
            var day = date.Value.ToUniversalTime().Date;
            query = query.Where(r => r.AttendanceDate == day);
        }
        if (staffId.HasValue) query = query.Where(r => r.StaffId == staffId.Value);
        if (from.HasValue) query = query.Where(r => r.AttendanceDate >= from.Value.ToUniversalTime().Date);
        if (to.HasValue) query = query.Where(r => r.AttendanceDate <= to.Value.ToUniversalTime().Date);

        var records = await query.OrderByDescending(r => r.AttendanceDate).ThenBy(r => r.StaffId).ToListAsync();
        var staffNames = await _db.Staff.Where(s => s.CompanyId == CompanyId)
            .ToDictionaryAsync(s => s.Id, s => new { s.Name, Role = s.Role.ToString() });
        return Ok(records.Select(r => ToDto(r, staffNames.GetValueOrDefault(r.StaffId)?.Name,
            staffNames.GetValueOrDefault(r.StaffId)?.Role)));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var record = await _db.StaffAttendanceRecords
            .FirstOrDefaultAsync(r => r.CompanyId == CompanyId && r.Id == id);
        if (record == null) return NotFound();
        var staff = await _db.Staff.FirstOrDefaultAsync(s => s.CompanyId == CompanyId && s.Id == record.StaffId);
        return Ok(ToDto(record, staff?.Name, staff?.Role.ToString()));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SaveStaffAttendanceRequest request)
    {
        var staff = await _db.Staff.FirstOrDefaultAsync(s => s.CompanyId == CompanyId && s.Id == request.StaffId);
        if (staff == null) return BadRequest(new { message = "Staff member was not found." });
        if (!TryParseStatus(request.Status, out var status))
            return BadRequest(new { message = "Invalid attendance status." });
        var day = request.AttendanceDate.ToUniversalTime().Date;
        if (await _db.StaffAttendanceRecords.AnyAsync(r => r.CompanyId == CompanyId && r.StaffId == request.StaffId && r.AttendanceDate == day))
            return Conflict(new { message = "Attendance already exists for this staff member and date." });

        try
        {
            var record = new StaffAttendanceRecord(CompanyId, request.StaffId, day, status,
                request.CheckIn, request.CheckOut, request.OvertimeHours, request.Notes);
            _db.StaffAttendanceRecords.Add(record);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetById), new { id = record.Id }, ToDto(record, staff.Name, staff.Role.ToString()));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveStaffAttendanceRequest request)
    {
        var record = await _db.StaffAttendanceRecords
            .FirstOrDefaultAsync(r => r.CompanyId == CompanyId && r.Id == id);
        if (record == null) return NotFound();
        var staff = await _db.Staff.FirstOrDefaultAsync(s => s.CompanyId == CompanyId && s.Id == request.StaffId);
        if (staff == null) return BadRequest(new { message = "Staff member was not found." });
        if (!TryParseStatus(request.Status, out var status))
            return BadRequest(new { message = "Invalid attendance status." });
        var day = request.AttendanceDate.ToUniversalTime().Date;
        if (await _db.StaffAttendanceRecords.AnyAsync(r => r.CompanyId == CompanyId && r.Id != id && r.StaffId == request.StaffId && r.AttendanceDate == day))
            return Conflict(new { message = "Attendance already exists for this staff member and date." });

        try
        {
            record.Update(day, status, request.CheckIn, request.CheckOut, request.OvertimeHours, request.Notes);
            await _db.SaveChangesAsync();
            return Ok(ToDto(record, staff.Name, staff.Role.ToString()));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var record = await _db.StaffAttendanceRecords
            .FirstOrDefaultAsync(r => r.CompanyId == CompanyId && r.Id == id);
        if (record == null) return NotFound();
        _db.StaffAttendanceRecords.Remove(record);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary([FromQuery] DateTime from, [FromQuery] DateTime to,
        [FromQuery] Guid? staffId)
    {
        var start = from.ToUniversalTime().Date;
        var end = to.ToUniversalTime().Date;
        var query = _db.StaffAttendanceRecords.Where(r =>
            r.CompanyId == CompanyId && r.AttendanceDate >= start && r.AttendanceDate <= end);
        if (staffId.HasValue) query = query.Where(r => r.StaffId == staffId.Value);
        var records = await query.ToListAsync();
        return Ok(new StaffAttendanceSummaryDto
        {
            Present = records.Count(r => r.Status is AttendanceStatus.Present or AttendanceStatus.Working or AttendanceStatus.Completed),
            Absent = records.Count(r => r.Status == AttendanceStatus.Absent),
            Leave = records.Count(r => r.Status == AttendanceStatus.Leave),
            HalfDay = records.Count(r => r.Status == AttendanceStatus.HalfDay),
            NotMarked = records.Count(r => r.Status == AttendanceStatus.NotMarked),
            TotalOvertimeHours = records.Sum(r => r.OvertimeHours)
        });
    }

    [HttpGet("today")]
    public async Task<IActionResult> GetToday()
    {
        var cid = CompanyId;
        var todayUtc = DateTime.UtcNow.Date;

        var staff = await _db.Staff
            .Where(s => s.CompanyId == cid && s.IsActive)
            .OrderBy(s => s.Name).ToListAsync();

        var todayRecords = await _db.StaffAttendanceRecords
            .Where(r => r.CompanyId == cid && r.AttendanceDate == todayUtc)
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
                CheckIn = record?.CheckInUtc?.ToString("HH:mm"),
                CheckOut = record?.CheckOutUtc?.ToString("HH:mm"),
                Status = record?.Status.ToString() ?? "NotMarked",
                AttendanceDate = todayUtc.ToString("yyyy-MM-dd"),
                OvertimeHours = record?.OvertimeHours ?? 0,
                Notes = record?.Notes,
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
            CheckIn = record.CheckInUtc?.ToString("HH:mm"),
            Status = "Working",
            AttendanceDate = record.AttendanceDate.ToString("yyyy-MM-dd"),
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
            CheckIn = record.CheckInUtc?.ToString("HH:mm"),
            CheckOut = record.CheckOutUtc?.ToString("HH:mm"),
            Status = "Completed",
            AttendanceDate = record.AttendanceDate.ToString("yyyy-MM-dd"),
        });
    }

    private static bool TryParseStatus(string value, out AttendanceStatus status) =>
        Enum.TryParse(value.Replace(" ", string.Empty), true, out status) &&
        status is AttendanceStatus.Present or AttendanceStatus.Absent or AttendanceStatus.Leave or AttendanceStatus.HalfDay or AttendanceStatus.NotMarked;

    private static StaffAttendanceDto ToDto(StaffAttendanceRecord record, string? staffName, string? staffRole) => new()
    {
        Id = record.Id,
        StaffId = record.StaffId,
        StaffName = staffName ?? string.Empty,
        StaffRole = staffRole ?? string.Empty,
        AttendanceDate = record.AttendanceDate.ToString("yyyy-MM-dd"),
        Status = record.Status.ToString(),
        CheckIn = record.CheckInUtc?.ToString("o"),
        CheckOut = record.CheckOutUtc?.ToString("o"),
        OvertimeHours = record.OvertimeHours,
        Notes = record.Notes,
        CreatedAtUtc = record.CreatedAtUtc,
        UpdatedAtUtc = record.UpdatedAtUtc,
    };
}
