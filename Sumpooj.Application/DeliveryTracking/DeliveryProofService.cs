using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class DeliveryProofService : IDeliveryProofService
{
    private readonly IDeliveryProofRepository _proofRepo;

    public DeliveryProofService(IDeliveryProofRepository proofRepo)
    {
        _proofRepo = proofRepo;
    }

    public async Task<DeliveryProof> UploadProofAsync(Guid deliveryId, string photoUrl, string? recipientName = null, string? note = null, Guid? userId = null, string? userName = null)
    {
        var proof = new DeliveryProof(deliveryId, photoUrl, recipientName, note);
        
        if (userId.HasValue || !string.IsNullOrWhiteSpace(userName))
        {
            proof.SetUploadContext(userId, userName);
        }

        await _proofRepo.AddAsync(proof);
        return proof;
    }

    public async Task<DeliveryProof?> GetDeliveryProofAsync(Guid deliveryId)
    {
        return await _proofRepo.GetByDeliveryIdAsync(deliveryId);
    }

    public async Task<DeliveryProof?> GetProofByIdAsync(Guid id)
    {
        return await _proofRepo.GetByIdAsync(id);
    }

    public async Task SetSignatureAsync(Guid proofId, string signatureData)
    {
        var proof = await _proofRepo.GetByIdAsync(proofId);
        if (proof != null)
        {
            proof.SetSignature(signatureData);
            await _proofRepo.UpdateAsync(proof);
        }
    }
}
