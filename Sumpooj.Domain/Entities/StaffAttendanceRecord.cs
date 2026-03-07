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
        Status = AttendanceStatus.Working;
    }

    public Guid CompanyId { get; private set; }
    public Guid StaffId { get; private set; }
    public DateTime CheckInUtc { get; private set; }
    public DateTime? CheckOutUtc { get; private set; }
    public AttendanceStatus Status { get; private set; }

    public void CheckOut()
    {
        CheckOutUtc = DateTime.UtcNow;
        Status = AttendanceStatus.Completed;
        MarkUpdated();
    }
}

public enum AttendanceStatus { Working, Completed, Absent }
