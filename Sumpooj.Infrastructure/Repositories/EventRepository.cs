using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Events;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class EventRepository : IEventRepository
{
    private readonly SumpoojDbContext _db;

    public EventRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<Event?> GetByIdAsync(Guid companyId, Guid id)
    {
        return await _db.Events
            .FirstOrDefaultAsync(e => e.CompanyId == companyId && e.Id == id);
    }

    public async Task<PagedResult<EventListDto>> SearchAsync(Guid companyId, EventSearchRequest request)
    {
        var query = _db.Events.Where(e => e.CompanyId == companyId && e.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.ToLower();
            query = query.Where(e =>
                e.EventName.ToLower().Contains(q) ||
                e.ClientName.ToLower().Contains(q) ||
                e.VenueName.ToLower().Contains(q));
        }

        if (!string.IsNullOrWhiteSpace(request.EventType) && Enum.TryParse<EventType>(request.EventType, true, out var eventType))
        {
            query = query.Where(e => e.EventType == eventType);
        }

        if (!string.IsNullOrWhiteSpace(request.Status) && Enum.TryParse<EventStatus>(request.Status, true, out var status))
        {
            query = query.Where(e => e.Status == status);
        }

        if (request.FromDate.HasValue)
        {
            query = query.Where(e => e.EventDate >= request.FromDate.Value);
        }

        if (request.ToDate.HasValue)
        {
            query = query.Where(e => e.EventDate <= request.ToDate.Value);
        }

        var total = await query.CountAsync();

        var items = await query
            .OrderBy(e => e.EventDate)
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(e => new EventListDto
            {
                Id = e.Id,
                EventName = e.EventName,
                EventType = e.EventType.ToString(),
                EventDate = e.EventDate,
                Status = e.Status.ToString(),
                ClientName = e.ClientName,
                VenueName = e.VenueName,
                Budget = e.Budget,
                TotalProposedAmount = e.TotalProposedAmount
            })
            .ToListAsync();

        return new PagedResult<EventListDto>(items, total, request.Page, request.PageSize);
    }

    public async Task<List<EventListDto>> GetUpcomingAsync(Guid companyId, int days = 30)
    {
        var endDate = DateTime.UtcNow.AddDays(days);
        
        return await _db.Events
            .Where(e => e.CompanyId == companyId && 
                        e.IsActive && 
                        e.EventDate >= DateTime.UtcNow && 
                        e.EventDate <= endDate)
            .OrderBy(e => e.EventDate)
            .Select(e => new EventListDto
            {
                Id = e.Id,
                EventName = e.EventName,
                EventType = e.EventType.ToString(),
                EventDate = e.EventDate,
                Status = e.Status.ToString(),
                ClientName = e.ClientName,
                VenueName = e.VenueName,
                Budget = e.Budget,
                TotalProposedAmount = e.TotalProposedAmount
            })
            .ToListAsync();
    }

    public async Task AddAsync(Event evt)
    {
        await _db.Events.AddAsync(evt);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(Event evt)
    {
        _db.Events.Update(evt);
        await _db.SaveChangesAsync();
    }
}
