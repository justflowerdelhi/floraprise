using Sumpooj.Domain.Entities;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class DeliveryTrackingWorkflowTests
{
    [Fact]
    public void Delivery_CanGenerateTokenBeforeAssignment_AndAssignSameRecord()
    {
        var delivery = CreateDelivery();
        var deliveryId = delivery.Id;
        var token = "tracking-token";
        var driverId = Guid.NewGuid();

        delivery.SetTrackingToken(token);
        delivery.AssignDeliveryPerson(driverId);

        Assert.Equal(deliveryId, delivery.Id);
        Assert.Equal(token, delivery.TrackingToken);
        Assert.Equal(driverId, delivery.DeliveryPersonId);
        Assert.Equal(DeliveryStatus.Assigned, delivery.Status);
    }

    [Fact]
    public void Delivery_FollowsDriverLifecycleToDelivered()
    {
        var delivery = CreateDelivery();
        delivery.AssignDeliveryPerson(Guid.NewGuid());

        delivery.MarkAccepted(delivery.DeliveryPersonId!.Value);
        delivery.MarkPickedUp();
        delivery.MarkOutForDelivery();
        delivery.MarkArrivedNearby();
        delivery.MarkDelivered();

        Assert.Equal(DeliveryStatus.Delivered, delivery.Status);
        Assert.NotNull(delivery.StartedAtUtc);
        Assert.NotNull(delivery.CompletedAtUtc);
    }

    [Fact]
    public void Delivery_RejectsGpsBeforeOutForDelivery()
    {
        var delivery = CreateDelivery();

        Assert.Throws<InvalidOperationException>(() => delivery.MarkArrivedNearby());
        Assert.Equal(DeliveryStatus.Created, delivery.Status);
    }

    private static Delivery CreateDelivery()
    {
        return new Delivery(
            Guid.NewGuid(),
            Guid.NewGuid(),
            DateTime.UtcNow,
            "Anytime",
            "Test address");
    }
}