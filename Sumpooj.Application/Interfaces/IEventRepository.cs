using Sumpooj.Application.Common;
using Sumpooj.Application.Events;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IEventRepository
{
    Task<Event?> GetByIdAsync(Guid companyId, Guid id);
    Task<PagedResult<EventListDto>> SearchAsync(Guid companyId, EventSearchRequest request);
    Task<List<EventListDto>> GetUpcomingAsync(Guid companyId, int days = 30);
    Task AddAsync(Event evt);
    Task UpdateAsync(Event evt);
}
