using Sumpooj.Application.DeliveryTracking.DTOs;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.DeliveryTracking;

public class DeliveryNotificationService
{
    private readonly IDeliveryRepository _deliveryRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly ICompanyRepository _companyRepository;

    public DeliveryNotificationService(
        IDeliveryRepository deliveryRepository,
        ICustomerRepository customerRepository,
        ICompanyRepository companyRepository)
    {
        _deliveryRepository = deliveryRepository;
        _customerRepository = customerRepository;
        _companyRepository = companyRepository;
    }

    public async Task<NotificationResponse> SendNotificationAsync(NotificationRequest request)
    {
        var delivery = await _deliveryRepository.GetByIdAsync(request.DeliveryId);
        if (delivery == null)
            throw new ArgumentException("Delivery not found", nameof(request.DeliveryId));

        // Customer and company info should be passed in the request or fetched from related entities
        // For now, we'll use the phone/email from the request directly
        var company = await _companyRepository.GetByIdAsync(delivery.CompanyId);

        var response = new NotificationResponse
        {
            SentAt = DateTime.UtcNow
        };

        // Send customer notification using request data
        if (!string.IsNullOrEmpty(request.CustomerPhone) && request.CustomerPhone != null)
        {
            // TODO: Integrate SMS service (Twilio, etc.)
            response.CustomerSMS = true;
        }

        if (!string.IsNullOrEmpty(request.CustomerEmail) && request.CustomerEmail != null)
        {
            // TODO: Integrate email service (SendGrid, etc.)
            response.CustomerEmail = true;
        }

        // Send florist notification
        if (company != null)
        {
            var floristMessage = BuildFloristMessage(request.Type, delivery, company);
            
            // SMS
            if (!string.IsNullOrEmpty(request.FloristPhone) && request.FloristPhone != null)
            {
                // TODO: Integrate SMS service
                response.FloristSMS = true;
            }

            // Email
            if (!string.IsNullOrEmpty(company.Email) && request.FloristEmail != null)
            {
                // TODO: Integrate email service
                response.FloristEmail = true;
            }
        }

        return response;
    }

    private string BuildCustomerMessage(NotificationType type, Delivery delivery)
    {
        return type switch
        {
            NotificationType.DeliveryAccepted => $"Your delivery #{delivery.SalesOrderId} has been accepted by our driver.",
            NotificationType.DeliveryPickedUp => $"Your delivery #{delivery.SalesOrderId} has been picked up and is on its way!",
            NotificationType.OutForDelivery => $"Your delivery #{delivery.SalesOrderId} is out for delivery. Expected arrival: {delivery.DeliveryDate:HH:mm}",
            NotificationType.ArrivedNearby => $"Your delivery #{delivery.SalesOrderId} has arrived nearby. The driver will be at your location shortly.",
            NotificationType.Delivered => $"Your delivery #{delivery.SalesOrderId} has been delivered successfully!",
            NotificationType.Failed => $"We were unable to complete delivery #{delivery.SalesOrderId}. Our team will contact you shortly.",
            NotificationType.Delayed => $"Your delivery #{delivery.SalesOrderId} is delayed. We apologize for the inconvenience.",
            _ => $"Update on your delivery #{delivery.SalesOrderId}"
        };
    }

    private string BuildFloristMessage(NotificationType type, Delivery delivery, Company company)
    {
        return type switch
        {
            NotificationType.DeliveryAccepted => $"Delivery #{delivery.SalesOrderId} accepted by driver.",
            NotificationType.DeliveryPickedUp => $"Delivery #{delivery.SalesOrderId} picked up by driver.",
            NotificationType.OutForDelivery => $"Delivery #{delivery.SalesOrderId} is out for delivery.",
            NotificationType.ArrivedNearby => $"Driver arrived nearby for delivery #{delivery.SalesOrderId}.",
            NotificationType.Delivered => $"Delivery #{delivery.SalesOrderId} completed successfully.",
            NotificationType.Failed => $"Delivery #{delivery.SalesOrderId} failed. Driver will report issue.",
            NotificationType.Delayed => $"Delivery #{delivery.SalesOrderId} is delayed.",
            _ => $"Update on delivery #{delivery.SalesOrderId}"
        };
    }
}
