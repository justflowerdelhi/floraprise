using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryProofRepository
{
    Task<DeliveryProof?> GetByIdAsync(Guid id);
    Task<DeliveryProof?> GetByDeliveryIdAsync(Guid deliveryId);
    Task AddAsync(DeliveryProof proof);
    Task UpdateAsync(DeliveryProof proof);
    Task DeleteAsync(Guid id);
}
