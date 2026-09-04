namespace Sumpooj.Domain.Entities;

/// <summary>Staff check-in / check-out record.</summary>
public class StaffAttendanceRecord : BaseEntity
{
    private StaffAttendanceRecord() { }

    public StaffAttendanceRecord(Guid companyId, Guid staffId, DateTime checkInUtc)
    {
        CompanyId = companyId;
        StaffId = staffId;
        CheckInUtc = EnsureUtc(checkInUtc);
        AttendanceDate = EnsureUtc(checkInUtc).Date;
        Status = AttendanceStatus.Working;
    }

    public StaffAttendanceRecord(
        Guid companyId,
        Guid staffId,
        DateTime attendanceDate,
        AttendanceStatus status,
        DateTime? checkInUtc,
        DateTime? checkOutUtc,
        int overtimeHours,
        string? notes)
    {
        CompanyId = companyId;
        StaffId = staffId;
        Update(attendanceDate, status, checkInUtc, checkOutUtc, overtimeHours, notes);
    }

    public Guid CompanyId { get; private set; }
    public Guid StaffId { get; private set; }
    public DateTime AttendanceDate { get; private set; }
    public DateTime? CheckInUtc { get; private set; }
    public DateTime? CheckOutUtc { get; private set; }
    public AttendanceStatus Status { get; private set; }
    public int OvertimeHours { get; private set; }
    public string? Notes { get; private set; }

    public void Update(
        DateTime attendanceDate,
        AttendanceStatus status,
        DateTime? checkInUtc,
        DateTime? checkOutUtc,
        int overtimeHours,
        string? notes)
    {
        var date = EnsureUtc(attendanceDate).Date;
        if (date > DateTime.UtcNow.Date)
            throw new InvalidOperationException("Future dates are not allowed.");
        if (status == AttendanceStatus.Present && !checkInUtc.HasValue)
            throw new InvalidOperationException("Check-in is required for Present status.");
        if (overtimeHours is < 0 or > 5)
            throw new InvalidOperationException("Overtime hours must be between 0 and 5.");
        if (checkInUtc.HasValue && checkOutUtc.HasValue && checkOutUtc < checkInUtc)
            throw new InvalidOperationException("Check-out cannot be before check-in.");

        AttendanceDate = date;
        Status = status;
        CheckInUtc = EnsureUtc(checkInUtc);
        CheckOutUtc = EnsureUtc(checkOutUtc);
        OvertimeHours = overtimeHours;
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim();
        MarkUpdated();
    }

    public void CheckOut()
    {
        CheckOutUtc = DateTime.UtcNow;
        Status = AttendanceStatus.Completed;
        MarkUpdated();
    }
}

public enum AttendanceStatus
{
    Working,
    Completed,
    Absent,
    Present,
    Leave,
    HalfDay,
    NotMarked
}
