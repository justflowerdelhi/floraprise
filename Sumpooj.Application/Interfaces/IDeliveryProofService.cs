using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IDeliveryProofService
{
    Task<DeliveryProof> UploadProofAsync(Guid deliveryId, string photoUrl, string? recipientName = null, string? note = null, Guid? userId = null, string? userName = null);
    Task<DeliveryProof?> GetDeliveryProofAsync(Guid deliveryId);
    Task<DeliveryProof?> GetProofByIdAsync(Guid id);
    Task SetSignatureAsync(Guid proofId, string signatureData);
}
