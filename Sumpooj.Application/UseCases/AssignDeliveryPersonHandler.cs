using Sumpooj.Application.Deliveries;
using Sumpooj.Application.Interfaces;
using System.Security.Cryptography;

namespace Sumpooj.Application.UseCases;

public class AssignDeliveryPersonHandler
{
    private readonly IDeliveryRepository _deliveryRepo;
    private readonly IStaffRepository _staffRepo;

    public AssignDeliveryPersonHandler(
        IDeliveryRepository deliveryRepo,
        IStaffRepository staffRepo)
    {
        _deliveryRepo = deliveryRepo;
        _staffRepo = staffRepo;
    }

    public async Task HandleAsync(AssignDeliveryPersonCommand command)
    {
        // 1. Load Delivery
        var delivery = await _deliveryRepo.GetByIdAsync(command.DeliveryId)
            ?? throw new InvalidOperationException($"Delivery '{command.DeliveryId}' not found.");

        // 2. Validate status — cannot assign if already delivered or cancelled
        if (delivery.Status == Domain.Entities.DeliveryStatus.Delivered)
            throw new InvalidOperationException("Cannot assign a delivery person to a delivery that is already delivered.");

        if (delivery.Status == Domain.Entities.DeliveryStatus.Cancelled)
            throw new InvalidOperationException("Cannot assign a delivery person to a cancelled delivery.");

        // 3. Validate Staff exists in the same company as the delivery
        var staff = await _staffRepo.GetByIdAsync(delivery.CompanyId, command.StaffId)
            ?? throw new InvalidOperationException($"Staff '{command.StaffId}' not found.");

        // 4. Generate secure tracking token if not already set
        if (string.IsNullOrWhiteSpace(delivery.TrackingToken))
        {
            var tokenBytes = new byte[16];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(tokenBytes);
            var token = Convert.ToHexString(tokenBytes).ToLowerInvariant();
            delivery.SetTrackingToken(token);
        }

        // 5. Assign delivery person via domain method
        delivery.AssignDeliveryPerson(command.StaffId);

        // 6. Save changes
        await _deliveryRepo.UpdateAsync(delivery);
    }
}
