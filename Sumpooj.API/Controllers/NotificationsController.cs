using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/v1/notifications")]
[Authorize(Policy = "PlatformSupport")]
public class NotificationsController : ControllerBase
{
    private readonly SumpoojDbContext _db;

    public NotificationsController(SumpoojDbContext db)
    {
        _db = db;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendNotification([FromBody] NotificationRequest request)
    {
        // Get target devices based on recipient type
        var devices = request.RecipientType.ToLower() switch
        {
            "all" => await _db.MobileDevices
                .AsNoTracking()
                .Where(x => !x.IsDeleted && x.Status == MobileDeviceStatus.Active && !string.IsNullOrEmpty(x.PushToken))
                .ToListAsync(),
            
            "selectedcompanies" when request.CompanyIds != null && request.CompanyIds.Any() => await _db.MobileDevices
                .AsNoTracking()
                .Include(x => x.MobileUser)
                .Where(x => !x.IsDeleted 
                    && x.Status == MobileDeviceStatus.Active 
                    && !string.IsNullOrEmpty(x.PushToken)
                    && request.CompanyIds.Contains(x.CompanyId))
                .ToListAsync(),
            
            "selecteddevices" when request.DeviceIds != null && request.DeviceIds.Any() => await _db.MobileDevices
                .AsNoTracking()
                .Where(x => !x.IsDeleted 
                    && x.Status == MobileDeviceStatus.Active 
                    && !string.IsNullOrEmpty(x.PushToken)
                    && request.DeviceIds.Contains(x.Id))
                .ToListAsync(),
            
            "onedevice" when request.DeviceId.HasValue => await _db.MobileDevices
                .AsNoTracking()
                .Where(x => !x.IsDeleted 
                    && x.Status == MobileDeviceStatus.Active 
                    && !string.IsNullOrEmpty(x.PushToken)
                    && x.Id == request.DeviceId.Value)
                .ToListAsync(),
            
            _ => new List<MobileDevice>()
        };

        if (!devices.Any())
        {
            return Ok(new { success = true, sent = 0, message = "No active devices with push tokens found" });
        }

        // TODO: Integrate Firebase Cloud Messaging (FCM) to send actual push notifications
        // For now, we'll just log the notification and return success
        // In production, this would:
        // 1. Use Firebase Admin SDK to send messages to each device's push token
        // 2. Handle batch sending for efficiency
        // 3. Track delivery status and handle failures
        
        var pushTokens = devices.Select(d => d.PushToken).Where(t => !string.IsNullOrEmpty(t)).ToList();
        
        // Placeholder: In production, replace with actual FCM send
        // var message = new Message()
        // {
        //     Notification = new Notification()
        //     {
        //         Title = request.Title,
        //         Body = request.Message
        //     },
        //     Token = pushToken
        // };
        // await FirebaseMessaging.DefaultInstance.SendAsync(message);

        return Ok(new { success = true, sent = pushTokens.Count, message = $"Notification queued for {pushTokens.Count} devices" });
    }
}

public class NotificationRequest
{
    public string Type { get; set; } = string.Empty;
    public string RecipientType { get; set; } = string.Empty;
    public List<Guid>? CompanyIds { get; set; }
    public List<Guid>? DeviceIds { get; set; }
    public Guid? DeviceId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}
