namespace Sumpooj.Application.Tasks;

public class TaskDto
{
    public Guid Id { get; set; }
    public Guid LocationId { get; set; }
    public string Title { get; set; } = default!;
    public string? Description { get; set; }
    public string Status { get; set; } = default!;
    public string Priority { get; set; } = default!;
    public Guid AssignedToStaffId { get; set; }
    public string? AssignedToStaffName { get; set; }
    public DateTime? DueDate { get; set; }
    public string? RelatedEntityType { get; set; }
    public Guid? RelatedEntityId { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class CreateTaskRequest
{
    public Guid LocationId { get; set; }
    public string Title { get; set; } = default!;
    public string? Description { get; set; }
    public string Priority { get; set; } = "Medium";
    public Guid AssignedToStaffId { get; set; }
    public DateTime? DueDate { get; set; }
    public string? RelatedEntityType { get; set; }
    public Guid? RelatedEntityId { get; set; }
}

public class UpdateTaskRequest
{
    public string? Title { get; set; }
    public string? Description { get; set; }
    public string? Priority { get; set; }
    public Guid? AssignedToStaffId { get; set; }
    public DateTime? DueDate { get; set; }
}

public class TaskSearchRequest
{
    public Guid? AssignedToStaffId { get; set; }
    public Guid? LocationId { get; set; }
    public string? Status { get; set; }
    public string? Priority { get; set; }
    public DateTime? DueDateFrom { get; set; }
    public DateTime? DueDateTo { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
