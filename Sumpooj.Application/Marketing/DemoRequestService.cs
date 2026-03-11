using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Marketing;

public class DemoRequestService
{
    private readonly IDemoRequestRepository _repo;
    private readonly ILeadNotificationService _notificationService;
    private readonly ILogger<DemoRequestService> _logger;

    public DemoRequestService(
        IDemoRequestRepository repo,
        ILeadNotificationService notificationService,
        ILogger<DemoRequestService> logger)
    {
        _repo = repo;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task SubmitAsync(DemoRequestDto dto)
    {
        var demoRequest = new DemoRequest(
            dto.FullName,
            dto.BusinessEmail,
            dto.BusinessType,
            dto.CurrentSoftware,
            dto.Notes);

        await _repo.AddAsync(demoRequest);

        _logger.LogInformation(
            "New demo request saved — {FullName} ({Email})",
            dto.FullName, dto.BusinessEmail);

        var submittedAt = dto.SubmittedAt ?? DateTime.UtcNow;

        // Fire notification (best-effort, don't fail the request)
        try
        {
            await _notificationService.NotifyNewDemoRequestAsync(
                dto.FullName,
                dto.BusinessEmail,
                dto.BusinessType,
                dto.CurrentSoftware,
                dto.Notes,
                submittedAt);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to send demo request notification for {Email}", dto.BusinessEmail);
        }
    }
}
