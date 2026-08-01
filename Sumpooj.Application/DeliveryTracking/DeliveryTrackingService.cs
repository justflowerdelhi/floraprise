using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class DeliveryTrackingService : IDeliveryTrackingService
{
    private readonly IDeliveryRepository _deliveryRepo;
    private readonly IDeliveryRouteRepository _routeRepo;
    private readonly IDeliveryLocationRepository _locationRepo;
    private readonly IDeliveryTimelineRepository _timelineRepo;
    private readonly IDeliveryProofRepository _proofRepo;
    private readonly IStaffRepository _staffRepo;
    private readonly IOrderRepository _orderRepo;
    private readonly ICustomerRepository _customerRepo;
    private readonly ITenantContext _tenantContext;

    public DeliveryTrackingService(
        IDeliveryRepository deliveryRepo,
        IDeliveryRouteRepository routeRepo,
        IDeliveryLocationRepository locationRepo,
        IDeliveryTimelineRepository timelineRepo,
        IDeliveryProofRepository proofRepo,
        IStaffRepository staffRepo,
        IOrderRepository orderRepo,
        ICustomerRepository customerRepo,
        ITenantContext tenantContext)
    {
        _deliveryRepo = deliveryRepo;
        _routeRepo = routeRepo;
        _locationRepo = locationRepo;
        _timelineRepo = timelineRepo;
        _proofRepo = proofRepo;
        _staffRepo = staffRepo;
        _orderRepo = orderRepo;
        _customerRepo = customerRepo;
        _tenantContext = tenantContext;
    }

    private Guid CompanyId => _tenantContext.CompanyId
        ?? throw new UnauthorizedAccessException("Company context required");

    public async Task<DeliveryTrackingSnapshot> GetTrackingByOrderIdAsync(Guid orderId)
    {
        var delivery = await _deliveryRepo.GetBySalesOrderIdAsync(orderId);

        if (delivery == null || delivery.CompanyId != CompanyId)
            throw new KeyNotFoundException("Delivery not found");

        return await BuildTrackingSnapshotAsync(delivery);
    }

    public async Task<DeliveryTrackingSnapshot> GetTrackingByDeliveryIdAsync(Guid deliveryId)
    {
        var delivery = await _deliveryRepo.GetByIdAsync(deliveryId);

        if (delivery == null || delivery.CompanyId != CompanyId)
            throw new KeyNotFoundException("Delivery not found");

        return await BuildTrackingSnapshotAsync(delivery);
    }

    public async Task<DeliveryTrackingSnapshot> GetTrackingByRouteIdAsync(Guid routeId)
    {
        var route = await _routeRepo.GetByIdAsync(routeId);

        if (route == null)
            throw new KeyNotFoundException("Route not found");

        var delivery = (await _deliveryRepo.GetAllAsync())
            .FirstOrDefault(d => d.DeliveryRouteId == routeId && d.CompanyId == CompanyId);

        if (delivery == null)
            throw new KeyNotFoundException("No deliveries found for this route");

        return await BuildTrackingSnapshotAsync(delivery, route);
    }

    public async Task<List<DeliveryWorkspaceRecord>> GetActiveDeliveriesAsync()
    {
        return await GetDeliveriesByStatusAsync("OutForDelivery");
    }

    public async Task<List<DeliveryWorkspaceRecord>> GetDeliveriesByStatusAsync(string status)
    {
        var deliveryStatus = Enum.TryParse<DeliveryStatus>(status, true, out var ds)
            ? ds
            : DeliveryStatus.Scheduled;

        var deliveries = (await _deliveryRepo.GetAllAsync())
            .Where(d => d.CompanyId == CompanyId && d.Status == deliveryStatus)
            .ToList();

        var orderIds = deliveries.Select(d => d.SalesOrderId).Distinct().ToList();
        var orders = await _orderRepo.GetByIdsAsync(CompanyId, orderIds);
        var ordersById = orders.ToDictionary(o => o.Id);

        var items = new List<DeliveryWorkspaceRecord>(deliveries.Count);
        foreach (var delivery in deliveries)
        {
            ordersById.TryGetValue(delivery.SalesOrderId, out var order);
            var customer = order == null
                ? null
                : await _customerRepo.GetByIdAsync(order.CustomerId);

            DeliveryDriverInfo? driver = null;
            if (delivery.DeliveryPersonId.HasValue)
            {
                var staff = await _staffRepo.GetByIdAsync(delivery.DeliveryPersonId.Value);
                if (staff != null)
                {
                    driver = new DeliveryDriverInfo
                    {
                        Name = staff.Name,
                        Phone = staff.Phone ?? "-"
                    };
                }
            }

            items.Add(new DeliveryWorkspaceRecord
            {
                AssignmentId = delivery.Id.ToString(),
                OrderId = delivery.SalesOrderId,
                OrderNo = order?.OrderNumber ?? delivery.SalesOrderId.ToString(),
                CustomerName = customer?.Name ?? order?.RecipientName ?? "Walk-in Customer",
                RecipientName = order?.RecipientName ?? customer?.Name ?? "-",
                DeliveryAddress = delivery.DeliveryAddress,
                DeliveryArea = ResolveDeliveryArea(delivery, order),
                CustomerPhone = delivery.CustomerPhone ?? order?.RecipientPhone ?? customer?.Phone,
                DeliveryTime = string.IsNullOrWhiteSpace(delivery.TimeSlot)
                    ? delivery.DeliveryDate.ToString("HH:mm")
                    : delivery.TimeSlot,
                Status = delivery.Status.ToString(),
                TrackingLink = $"/track/{delivery.Id}",
                Eta = delivery.DeliveryDate,
                UpdatedAt = delivery.UpdatedAtUtc ?? delivery.CreatedAtUtc,
                Driver = driver
            });
        }

        return items;
    }

    private static string ResolveDeliveryArea(Delivery delivery, Order? order)
    {
        if (!string.IsNullOrWhiteSpace(delivery.PostalCode))
            return delivery.PostalCode;
        if (!string.IsNullOrWhiteSpace(order?.DeliveryPincode))
            return order.DeliveryPincode!;

        var address = delivery.DeliveryAddress.Trim();
        if (string.IsNullOrWhiteSpace(address)) return "-";

        var parts = address
            .Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
        return parts.Length == 0 ? address : parts[^1];
    }

    public async Task RecordHeartbeatAsync(Guid deliveryId, Guid? driverId = null)
    {
        var delivery = await _deliveryRepo.GetByIdAsync(deliveryId);

        if (delivery == null || delivery.CompanyId != CompanyId)
            throw new KeyNotFoundException("Delivery not found");

        if (driverId.HasValue && delivery.DeliveryPersonId != driverId)
        {
            delivery.AssignDeliveryPerson(driverId.Value);
        }

        // Update the delivery's updated timestamp
        delivery.MarkUpdated();
        await _deliveryRepo.UpdateAsync(delivery);
    }

    private async Task<DeliveryTrackingSnapshot> BuildTrackingSnapshotAsync(Delivery delivery, DeliveryRoute? route = null)
    {
        var locations = await _locationRepo.GetByDeliveryIdAsync(delivery.Id);
        var timeline = await _timelineRepo.GetByDeliveryIdAsync(delivery.Id);
        var proof = await _proofRepo.GetByDeliveryIdAsync(delivery.Id);

        DeliveryDriverInfo? driverInfo = null;
        if (delivery.DeliveryPersonId.HasValue)
        {
            var staff = await _staffRepo.GetByIdAsync(delivery.DeliveryPersonId.Value);
            if (staff != null)
            {
                driverInfo = new DeliveryDriverInfo
                {
                    Name = staff.Name,
                    Phone = staff.Phone ?? "-"
                };
            }
        }

        _ = route ?? (delivery.DeliveryRouteId.HasValue
            ? await _routeRepo.GetByIdAsync(delivery.DeliveryRouteId.Value)
            : null);

        return new DeliveryTrackingSnapshot
        {
            AssignmentId = delivery.Id,
            OrderId = delivery.SalesOrderId,
            TrackingId = delivery.Id.ToString(),
            TrackingLink = $"/track/{delivery.Id}",
            Status = delivery.Status.ToString(),
            Eta = delivery.DeliveryDate,
            Driver = driverInfo,
            Route = locations.Select(l => new DeliveryLocationPoint
            {
                Latitude = l.Latitude,
                Longitude = l.Longitude,
                RecordedAt = l.RecordedAt,
                SpeedKph = l.SpeedKph
            }).ToList(),
            Timeline = timeline.Select(t => new DeliveryTimelineEvent
            {
                Status = t.Status,
                RecordedAt = t.RecordedAt,
                Note = t.Note
            }).ToList(),
            Proof = proof != null ? new DeliveryProofInfo
            {
                PhotoUrl = proof.PhotoUrl,
                Note = proof.Note,
                RecipientName = proof.RecipientName,
                RecordedAt = proof.RecordedAt
            } : null,
            LastLocation = locations
                .OrderByDescending(x => x.RecordedAt)
                .Select(x => new DeliveryLocationPoint
                {
                    Latitude = x.Latitude,
                    Longitude = x.Longitude,
                    RecordedAt = x.RecordedAt,
                    SpeedKph = x.SpeedKph
                })
                .FirstOrDefault()
        };
    }
}
