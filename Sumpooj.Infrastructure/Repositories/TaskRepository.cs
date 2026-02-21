using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Tasks;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class TaskRepository : ITaskRepository
{
    private readonly SumpoojDbContext _db;

    public TaskRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<StaffTask?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Tasks
            .FirstOrDefaultAsync(t => t.CompanyId == companyId && t.Id == id);
    }

    public async Task<PagedResult<TaskDto>> SearchAsync(Guid companyId, TaskSearchRequest request)
    {
        var query = _db.Tasks.Where(t => t.CompanyId == companyId);

        if (request.AssignedToStaffId.HasValue)
        {
            query = query.Where(t => t.AssignedToStaffId == request.AssignedToStaffId.Value);
        }

        if (request.LocationId.HasValue)
        {
            query = query.Where(t => t.LocationId == request.LocationId.Value);
        }

        if (!string.IsNullOrWhiteSpace(request.Status) && Enum.TryParse<Domain.Entities.TaskStatus>(request.Status, true, out var status))
        {
            query = query.Where(t => t.Status == status);
        }

        if (!string.IsNullOrWhiteSpace(request.Priority) && Enum.TryParse<TaskPriority>(request.Priority, true, out var priority))
        {
            query = query.Where(t => t.Priority == priority);
        }

        if (request.DueDateFrom.HasValue)
        {
            query = query.Where(t => t.DueDate >= request.DueDateFrom.Value);
        }

        if (request.DueDateTo.HasValue)
        {
            query = query.Where(t => t.DueDate <= request.DueDateTo.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(t => t.DueDate)
            .ThenByDescending(t => t.Priority)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(t => new TaskDto
            {
                Id = t.Id,
                LocationId = t.LocationId,
                Title = t.Title,
                Description = t.Description,
                Status = t.Status.ToString(),
                Priority = t.Priority.ToString(),
                AssignedToStaffId = t.AssignedToStaffId,
                DueDate = t.DueDate,
                RelatedEntityType = t.RelatedEntityType != null ? t.RelatedEntityType.ToString() : null,
                RelatedEntityId = t.RelatedEntityId,
                CreatedAtUtc = t.CreatedAtUtc
            })
            .ToListAsync();

        return new PagedResult<TaskDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<TaskDto>> GetByStaffIdAsync(Guid companyId, Guid staffId)
    {
        return await _db.Tasks
            .Where(t => t.CompanyId == companyId && t.AssignedToStaffId == staffId)
            .OrderBy(t => t.DueDate)
            .ThenByDescending(t => t.Priority)
            .Select(t => new TaskDto
            {
                Id = t.Id,
                LocationId = t.LocationId,
                Title = t.Title,
                Description = t.Description,
                Status = t.Status.ToString(),
                Priority = t.Priority.ToString(),
                AssignedToStaffId = t.AssignedToStaffId,
                DueDate = t.DueDate,
                RelatedEntityType = t.RelatedEntityType != null ? t.RelatedEntityType.ToString() : null,
                RelatedEntityId = t.RelatedEntityId,
                CreatedAtUtc = t.CreatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<List<TaskDto>> GetPendingTasksAsync(Guid companyId, Guid? locationId = null)
    {
        var query = _db.Tasks
            .Where(t => t.CompanyId == companyId && t.Status != Domain.Entities.TaskStatus.Completed);

        if (locationId.HasValue)
        {
            query = query.Where(t => t.LocationId == locationId.Value);
        }

        return await query
            .OrderBy(t => t.DueDate)
            .ThenByDescending(t => t.Priority)
            .Select(t => new TaskDto
            {
                Id = t.Id,
                LocationId = t.LocationId,
                Title = t.Title,
                Description = t.Description,
                Status = t.Status.ToString(),
                Priority = t.Priority.ToString(),
                AssignedToStaffId = t.AssignedToStaffId,
                DueDate = t.DueDate,
                RelatedEntityType = t.RelatedEntityType != null ? t.RelatedEntityType.ToString() : null,
                RelatedEntityId = t.RelatedEntityId,
                CreatedAtUtc = t.CreatedAtUtc
            })
            .ToListAsync();
    }

    public async Task<int> GetPendingTaskCountAsync(Guid companyId)
    {
        return await _db.Tasks
            .CountAsync(t => t.CompanyId == companyId && t.Status != Domain.Entities.TaskStatus.Completed);
    }

    public async Task AddAsync(StaffTask task)
    {
        await _db.Tasks.AddAsync(task);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(StaffTask task)
    {
        _db.Tasks.Update(task);
        await _db.SaveChangesAsync();
    }
}
