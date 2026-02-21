namespace Sumpooj.Domain.Entities;

public class StaffTask : BaseEntity
{
    private StaffTask() { }

    public StaffTask(
        Guid companyId,
        Guid locationId,
        string title,
        Guid assignedToStaffId,
        TaskPriority priority = TaskPriority.Medium)
    {
        CompanyId = companyId;
        LocationId = locationId;
        Title = title;
        AssignedToStaffId = assignedToStaffId;
        Priority = priority;
        Status = Domain.Entities.TaskStatus.Pending;
    }

    public Guid CompanyId { get; private set; }
    public Guid LocationId { get; private set; }
    public string Title { get; private set; }
    public string? Description { get; private set; }
    public TaskStatus Status { get; private set; }
    public TaskPriority Priority { get; private set; }
    public Guid AssignedToStaffId { get; private set; }
    public DateTime? DueDate { get; private set; }

    // Related Entity
    public RelatedEntityType? RelatedEntityType { get; private set; }
    public Guid? RelatedEntityId { get; private set; }

    public void UpdateDetails(string title, string? description)
    {
        Title = title;
        Description = description;
        MarkUpdated();
    }

    public void SetDueDate(DateTime? dueDate)
    {
        DueDate = dueDate;
        MarkUpdated();
    }

    public void SetPriority(TaskPriority priority)
    {
        Priority = priority;
        MarkUpdated();
    }

    public void LinkToEntity(RelatedEntityType entityType, Guid entityId)
    {
        RelatedEntityType = entityType;
        RelatedEntityId = entityId;
        MarkUpdated();
    }

    public void Reassign(Guid staffId)
    {
        AssignedToStaffId = staffId;
        MarkUpdated();
    }

    public void StartProgress()
    {
        if (Status != Domain.Entities.TaskStatus.Pending)
            throw new InvalidOperationException("Can only start pending tasks");

        Status = Domain.Entities.TaskStatus.InProgress;
        MarkUpdated();
    }

    public void Complete()
    {
        Status = Domain.Entities.TaskStatus.Completed;
        MarkUpdated();
    }

    public void Reopen()
    {
        Status = Domain.Entities.TaskStatus.Pending;
        MarkUpdated();
    }
}
