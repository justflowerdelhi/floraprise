using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IVendorExecutionRepository
{
    Task<VendorExecution?> GetByIdAsync(Guid id);
    Task<VendorExecution?> GetBySalesOrderIdAsync(Guid salesOrderId);
    Task AddAsync(VendorExecution vendorExecution);
    Task UpdateAsync(VendorExecution vendorExecution);
}
