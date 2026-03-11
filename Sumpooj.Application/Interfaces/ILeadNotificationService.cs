namespace Sumpooj.Application.Interfaces;

public interface ILeadNotificationService
{
    Task NotifyNewDemoRequestAsync(
        string fullName,
        string businessEmail,
        string? businessType,
        string? currentSoftware,
        string? notes,
        DateTime submittedAt);
}
