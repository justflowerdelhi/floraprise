namespace Sumpooj.Application.Interfaces;

public interface ITaskAssignmentNotificationService
{
    Task NotifyTaskAssignedAsync(
        string staffName,
        string? staffPhone,
        string taskTitle,
        string? taskDescription,
        string taskPriority,
        DateTime? dueDate,
        bool isReassignment);
}