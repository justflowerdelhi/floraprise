using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Tasks;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class TaskService
{
    private readonly ITaskRepository _taskRepository;
    private readonly IStaffRepository _staffRepository;
    private readonly ITaskAssignmentNotificationService _taskAssignmentNotificationService;

    public TaskService(
        ITaskRepository taskRepository,
        IStaffRepository staffRepository,
        ITaskAssignmentNotificationService taskAssignmentNotificationService)
    {
        _taskRepository = taskRepository;
        _staffRepository = staffRepository;
        _taskAssignmentNotificationService = taskAssignmentNotificationService;
    }

    public async Task<TaskDto?> GetByIdAsync(Guid companyId, Guid id)
    {
        var task = await _taskRepository.GetByIdAsync(companyId, id);
        if (task == null) return null;

        var dto = MapToDto(task);
        var staff = await _staffRepository.GetByIdAsync(companyId, task.AssignedToStaffId);
        dto.AssignedToStaffName = staff?.Name;
        return dto;
    }

    public async Task<PagedResult<TaskDto>> SearchAsync(Guid companyId, TaskSearchRequest request)
    {
        return await _taskRepository.SearchAsync(companyId, request);
    }

    public async Task<List<TaskDto>> GetByStaffIdAsync(Guid companyId, Guid staffId)
    {
        return await _taskRepository.GetByStaffIdAsync(companyId, staffId);
    }

    public async Task<List<TaskDto>> GetPendingTasksAsync(Guid companyId, Guid? locationId = null)
    {
        return await _taskRepository.GetPendingTasksAsync(companyId, locationId);
    }

    public async Task<Guid> CreateAsync(Guid companyId, CreateTaskRequest request)
    {
        // Validate staff exists
        var staff = await _staffRepository.GetByIdAsync(companyId, request.AssignedToStaffId)
            ?? throw new KeyNotFoundException("Staff not found");

        if (!Enum.TryParse<TaskPriority>(request.Priority, true, out var priority))
            priority = TaskPriority.Medium;

        var task = new StaffTask(
            companyId,
            request.LocationId,
            request.Title,
            request.AssignedToStaffId,
            priority);

        if (!string.IsNullOrEmpty(request.Description))
        {
            task.UpdateDetails(request.Title, request.Description);
        }

        if (request.DueDate.HasValue)
        {
            task.SetDueDate(request.DueDate);
        }

        if (!string.IsNullOrEmpty(request.RelatedEntityType) && request.RelatedEntityId.HasValue)
        {
            if (Enum.TryParse<RelatedEntityType>(request.RelatedEntityType, true, out var entityType))
            {
                task.LinkToEntity(entityType, request.RelatedEntityId.Value);
            }
        }

        await _taskRepository.AddAsync(task);

        await _taskAssignmentNotificationService.NotifyTaskAssignedAsync(
            staff.Name,
            staff.Phone,
            task.Title,
            task.Description,
            task.Priority.ToString(),
            task.DueDate,
            isReassignment: false);

        return task.Id;
    }

    public async Task UpdateAsync(Guid companyId, Guid id, UpdateTaskRequest request)
    {
        var task = await _taskRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Task not found");

        if (request.Title != null || request.Description != null)
        {
            task.UpdateDetails(
                request.Title ?? task.Title,
                request.Description ?? task.Description);
        }

        if (request.Priority != null && Enum.TryParse<TaskPriority>(request.Priority, true, out var priority))
        {
            task.SetPriority(priority);
        }

        if (request.AssignedToStaffId.HasValue)
        {
            var staff = await _staffRepository.GetByIdAsync(companyId, request.AssignedToStaffId.Value)
                ?? throw new KeyNotFoundException("Staff not found");

            var isChanged = task.AssignedToStaffId != request.AssignedToStaffId.Value;
            task.Reassign(request.AssignedToStaffId.Value);

            if (isChanged)
            {
                await _taskAssignmentNotificationService.NotifyTaskAssignedAsync(
                    staff.Name,
                    staff.Phone,
                    task.Title,
                    task.Description,
                    task.Priority.ToString(),
                    task.DueDate,
                    isReassignment: true);
            }
        }

        if (request.DueDate.HasValue)
        {
            task.SetDueDate(request.DueDate);
        }

        await _taskRepository.UpdateAsync(task);
    }

    public async Task StartAsync(Guid companyId, Guid id)
    {
        var task = await _taskRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Task not found");

        task.StartProgress();
        await _taskRepository.UpdateAsync(task);
    }

    public async Task CompleteAsync(Guid companyId, Guid id)
    {
        var task = await _taskRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Task not found");

        task.Complete();
        await _taskRepository.UpdateAsync(task);
    }

    public async Task ReopenAsync(Guid companyId, Guid id)
    {
        var task = await _taskRepository.GetByIdAsync(companyId, id)
            ?? throw new KeyNotFoundException("Task not found");

        task.Reopen();
        await _taskRepository.UpdateAsync(task);
    }

    private static TaskDto MapToDto(StaffTask task) => new()
    {
        Id = task.Id,
        LocationId = task.LocationId,
        Title = task.Title,
        Description = task.Description,
        Status = task.Status.ToString(),
        Priority = task.Priority.ToString(),
        AssignedToStaffId = task.AssignedToStaffId,
        DueDate = task.DueDate,
        RelatedEntityType = task.RelatedEntityType?.ToString(),
        RelatedEntityId = task.RelatedEntityId,
        CreatedAtUtc = task.CreatedAtUtc
    };
}
