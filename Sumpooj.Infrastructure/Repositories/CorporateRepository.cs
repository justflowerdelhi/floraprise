using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Corporate;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class CorporateRepository : ICorporateRepository
{
    private readonly SumpoojDbContext _db;

    public CorporateRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<PagedResult<CorporateClientDto>> SearchClientsAsync(Guid companyId, string? query, bool? isActive, int page, int pageSize)
    {
        var q = _db.CorporateClients.AsQueryable();

        if (!string.IsNullOrWhiteSpace(query))
        {
            var term = query.Trim().ToLower();
            q = q.Where(x => x.Name.ToLower().Contains(term) || x.BillingEmail.ToLower().Contains(term));
        }

        if (isActive.HasValue)
            q = q.Where(x => x.IsActive == isActive.Value);

        var total = await q.CountAsync();

        var items = await q
            .OrderBy(x => x.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new CorporateClientDto
            {
                Id = x.Id,
                CustomerId = x.CustomerId,
                Name = x.Name,
                BillingEmail = x.BillingEmail,
                Phone = x.Phone,
                CreditLimit = x.CreditLimit,
                PaymentTerms = x.PaymentTerms,
                BillingCycle = x.BillingCycle,
                DefaultProductId = x.DefaultProductId,
                DefaultMessage = x.DefaultMessage,
                IsActive = x.IsActive,
                CreatedAtUtc = x.CreatedAtUtc
            })
            .ToListAsync();

        foreach (var item in items)
        {
            item.OutstandingAmount = await GetClientOutstandingAsync(companyId, item.Id);
            item.ActiveEmployees = await _db.CorporateEmployees.CountAsync(e => e.ClientId == item.Id && e.IsActive);
        }

        return new PagedResult<CorporateClientDto>(items, total, page, pageSize);
    }

    public async Task<CorporateClient?> GetClientByIdAsync(Guid companyId, Guid clientId)
    {
        return await _db.CorporateClients.FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == clientId);
    }

    public async Task AddClientAsync(CorporateClient client)
    {
        await _db.CorporateClients.AddAsync(client);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateClientAsync(CorporateClient client)
    {
        _db.CorporateClients.Update(client);
        await _db.SaveChangesAsync();
    }

    public async Task<List<CorporateEmployeeDto>> GetEmployeesAsync(Guid companyId, Guid clientId, bool activeOnly = false)
    {
        var query = _db.CorporateEmployees.Where(x => x.CompanyId == companyId && x.ClientId == clientId);
        if (activeOnly)
            query = query.Where(x => x.IsActive);

        return await query
            .OrderBy(x => x.Name)
            .Select(x => new CorporateEmployeeDto
            {
                Id = x.Id,
                ClientId = x.ClientId,
                Name = x.Name,
                DateOfBirth = x.DateOfBirth,
                Address = x.Address,
                IsActive = x.IsActive
            })
            .ToListAsync();
    }

    public async Task<CorporateEmployee?> GetEmployeeByIdAsync(Guid companyId, Guid employeeId)
    {
        return await _db.CorporateEmployees.FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == employeeId);
    }

    public async Task AddEmployeeAsync(CorporateEmployee employee)
    {
        await _db.CorporateEmployees.AddAsync(employee);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateEmployeeAsync(CorporateEmployee employee)
    {
        _db.CorporateEmployees.Update(employee);
        await _db.SaveChangesAsync();
    }

    public async Task<CorporateOrderMeta?> GetOrderMetaByOrderIdAsync(Guid companyId, Guid orderId)
    {
        return await _db.CorporateOrderMetas.FirstOrDefaultAsync(x => x.CompanyId == companyId && x.OrderId == orderId);
    }

    public async Task AddOrderMetaAsync(CorporateOrderMeta meta)
    {
        await _db.CorporateOrderMetas.AddAsync(meta);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateOrderMetaAsync(CorporateOrderMeta meta)
    {
        _db.CorporateOrderMetas.Update(meta);
        await _db.SaveChangesAsync();
    }

    public async Task<List<PendingCorporateApprovalOrderDto>> GetPendingAutoCreatedOrdersAsync(Guid companyId)
    {
        return await _db.CorporateOrderMetas
            .Include(x => x.Order)
            .Include(x => x.Client)
            .Include(x => x.Employee)
            .Where(x => x.CompanyId == companyId
                        && x.IsAutoCreated
                        && x.NeedsApproval
                        && x.Order != null
                        && x.Order.Status == OrderStatus.AutoCreated)
            .OrderBy(x => x.Order!.DeliveryDate)
            .Select(x => new PendingCorporateApprovalOrderDto
            {
                OrderId = x.OrderId,
                OrderNumber = x.Order!.OrderNumber,
                ClientId = x.ClientId,
                ClientName = x.Client != null ? x.Client.Name : "Corporate Client",
                EmployeeId = x.EmployeeId,
                EmployeeName = x.Employee != null ? x.Employee.Name : null,
                OrderDateUtc = x.Order.OrderDate,
                DeliveryDateUtc = x.Order.DeliveryDate,
                DeliveryAddress = x.Order.DeliveryAddress,
                TotalAmount = x.Order.TotalAmount,
                NeedsApproval = x.NeedsApproval,
                AutomationDateUtc = x.AutomationDateUtc,
            })
            .ToListAsync();
    }

    public async Task<bool> HasBirthdayOrderForDateAsync(Guid companyId, Guid employeeId, DateTime dateUtc)
    {
        var dayStart = DateTime.SpecifyKind(dateUtc.Date, DateTimeKind.Utc);
        var dayEnd = dayStart.AddDays(1);

        return await _db.CorporateOrderMetas.AnyAsync(x =>
            x.CompanyId == companyId
            && x.EmployeeId == employeeId
            && x.IsAutoCreated
            && x.AutomationDateUtc.HasValue
            && x.AutomationDateUtc.Value >= dayStart
            && x.AutomationDateUtc.Value < dayEnd);
    }

    public async Task<List<CorporateOrderMeta>> GetPendingOrderMetaForInvoiceAsync(Guid companyId, Guid clientId, DateTime startDateUtc, DateTime endDateUtc)
    {
        var start = DateTime.SpecifyKind(startDateUtc.Date, DateTimeKind.Utc);
        var endExclusive = DateTime.SpecifyKind(endDateUtc.Date, DateTimeKind.Utc).AddDays(1);

        return await _db.CorporateOrderMetas
            .Include(x => x.Order)
            .Where(x => x.CompanyId == companyId
                        && x.ClientId == clientId
                        && x.BillingStatus == CorporateBillingStatus.Pending
                        && x.Order != null
                        && x.Order.OrderDate >= start
                        && x.Order.OrderDate < endExclusive
                        && x.Order.Status != OrderStatus.Cancelled)
            .ToListAsync();
    }

    public async Task AddInvoiceAsync(CorporateInvoice invoice)
    {
        await _db.CorporateInvoices.AddAsync(invoice);
        await _db.SaveChangesAsync();
    }

    public async Task<CorporateInvoice?> GetInvoiceByIdAsync(Guid companyId, Guid invoiceId)
    {
        return await _db.CorporateInvoices
            .Include(x => x.Lines)
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == invoiceId);
    }

    public async Task UpdateInvoiceAsync(CorporateInvoice invoice)
    {
        _db.CorporateInvoices.Update(invoice);
        await _db.SaveChangesAsync();
    }

    public async Task<List<CorporateInvoiceDto>> GetClientInvoicesAsync(Guid companyId, Guid clientId)
    {
        return await _db.CorporateInvoices
            .Where(x => x.CompanyId == companyId && x.ClientId == clientId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Select(x => new CorporateInvoiceDto
            {
                Id = x.Id,
                ClientId = x.ClientId,
                StartDateUtc = x.StartDateUtc,
                EndDateUtc = x.EndDateUtc,
                TotalAmount = x.TotalAmount,
                Status = x.Status,
                PaidAtUtc = x.PaidAtUtc,
                CreatedAtUtc = x.CreatedAtUtc,
                Lines = x.Lines
                    .OrderBy(l => l.OrderDateUtc)
                    .Select(l => new CorporateInvoiceLineDto
                    {
                        OrderId = l.OrderId,
                        OrderNumber = l.OrderNumber,
                        OrderDateUtc = l.OrderDateUtc,
                        Amount = l.Amount
                    })
                    .ToList()
            })
            .ToListAsync();
    }

    public async Task<decimal> GetClientOutstandingAsync(Guid companyId, Guid clientId)
    {
        var invoiced = await _db.CorporateOrderMetas
            .Include(x => x.Order)
            .Where(x => x.CompanyId == companyId
                        && x.ClientId == clientId
                        && x.BillingStatus != CorporateBillingStatus.Paid
                        && x.Order != null
                        && x.Order.Status != OrderStatus.Cancelled)
            .Select(x => x.Order!.TotalAmount)
            .ToListAsync();

        return invoiced.Sum();
    }

    public async Task<List<CorporateEmployee>> GetTodaysBirthdayEmployeesAsync(Guid companyId, DateTime dateUtc)
    {
        var month = dateUtc.Month;
        var day = dateUtc.Day;

        return await _db.CorporateEmployees
            .Include(x => x.Client)
            .Where(x => x.CompanyId == companyId
                        && x.IsActive
                        && x.Client != null
                        && x.Client.IsActive
                        && x.DateOfBirth.Month == month
                        && x.DateOfBirth.Day == day)
            .ToListAsync();
    }
}
