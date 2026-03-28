using Sumpooj.Application.Corporate;
using Sumpooj.Application.Common;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ICorporateRepository
{
    Task<PagedResult<CorporateClientDto>> SearchClientsAsync(Guid companyId, string? query, bool? isActive, int page, int pageSize);
    Task<CorporateClient?> GetClientByIdAsync(Guid companyId, Guid clientId);
    Task AddClientAsync(CorporateClient client);
    Task UpdateClientAsync(CorporateClient client);

    Task<List<CorporateEmployeeDto>> GetEmployeesAsync(Guid companyId, Guid clientId, bool activeOnly = false);
    Task<CorporateEmployee?> GetEmployeeByIdAsync(Guid companyId, Guid employeeId);
    Task AddEmployeeAsync(CorporateEmployee employee);
    Task UpdateEmployeeAsync(CorporateEmployee employee);

    Task<CorporateOrderMeta?> GetOrderMetaByOrderIdAsync(Guid companyId, Guid orderId);
    Task AddOrderMetaAsync(CorporateOrderMeta meta);
    Task UpdateOrderMetaAsync(CorporateOrderMeta meta);
    Task<List<PendingCorporateApprovalOrderDto>> GetPendingAutoCreatedOrdersAsync(Guid companyId);
    Task<bool> HasBirthdayOrderForDateAsync(Guid companyId, Guid employeeId, DateTime dateUtc);
    Task<List<CorporateOrderMeta>> GetPendingOrderMetaForInvoiceAsync(Guid companyId, Guid clientId, DateTime startDateUtc, DateTime endDateUtc);

    Task AddInvoiceAsync(CorporateInvoice invoice);
    Task<CorporateInvoice?> GetInvoiceByIdAsync(Guid companyId, Guid invoiceId);
    Task UpdateInvoiceAsync(CorporateInvoice invoice);
    Task<List<CorporateInvoiceDto>> GetClientInvoicesAsync(Guid companyId, Guid clientId);

    Task<decimal> GetClientOutstandingAsync(Guid companyId, Guid clientId);
    Task<List<CorporateEmployee>> GetTodaysBirthdayEmployeesAsync(Guid companyId, DateTime dateUtc);
}