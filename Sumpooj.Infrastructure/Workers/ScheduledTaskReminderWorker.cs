using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Workers;

public sealed class ScheduledTaskReminderWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ScheduledTaskReminderWorker> _logger;
    private static readonly TimeSpan CheckInterval = TimeSpan.FromSeconds(30);

    public ScheduledTaskReminderWorker(
        IServiceProvider serviceProvider,
        ILogger<ScheduledTaskReminderWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("ScheduledTaskReminderWorker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessDueTasksAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled error in ScheduledTaskReminderWorker cycle.");
            }

            try
            {
                await Task.Delay(CheckInterval, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
        }

        _logger.LogInformation("ScheduledTaskReminderWorker stopped.");
    }

    private async Task ProcessDueTasksAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SumpoojDbContext>();
        var fcmService = scope.ServiceProvider.GetRequiredService<IFcmNotificationService>();

        var utcNow = DateTime.UtcNow;

        var dueTasks = await db.SchedulerRecords
            .Where(x => !x.DeletedAtUtc.HasValue &&
                        x.Status != "completed" &&
                        x.Status != "cancelled" &&
                        x.Status != "deferred" &&
                        (x.ScheduledAt <= utcNow && (!x.NextReminderAt.HasValue || x.NextReminderAt.Value <= utcNow)))
            .OrderBy(x => x.ScheduledAt)
            .Take(50)
            .ToListAsync(cancellationToken);

        if (dueTasks.Count == 0) return;

        _logger.LogDebug("ScheduledTaskReminderWorker found {Count} due task(s).", dueTasks.Count);

        foreach (var task in dueTasks)
        {
            try
            {
                var companyDevices = await db.MobileDevices
                    .Where(d => d.CompanyId == task.CompanyId &&
                                d.Status == MobileDeviceStatus.Active &&
                                !d.IsDeleted &&
                                !string.IsNullOrEmpty(d.PushToken))
                    .ToListAsync(cancellationToken);

                var targetDevices = companyDevices;
                if (task.AssignedStaffId.HasValue)
                {
                    var staffDevices = companyDevices
                        .Where(d => d.MobileUserId == task.AssignedStaffId.Value)
                        .ToList();

                    if (staffDevices.Count > 0)
                    {
                        targetDevices = staffDevices;
                    }
                }

                if (targetDevices.Count > 0)
                {
                    var customerName = string.Empty;
                    if (task.LinkedCustomerId.HasValue)
                    {
                        var customer = await db.Customers
                            .FirstOrDefaultAsync(c => c.Id == task.LinkedCustomerId.Value && c.CompanyId == task.CompanyId, cancellationToken);
                        if (customer != null) customerName = customer.Name;
                    }

                    var bodyBuilder = new StringBuilder();
                    if (!string.IsNullOrWhiteSpace(customerName))
                    {
                        bodyBuilder.AppendLine($"Customer: {customerName}");
                    }
                    if (task.LinkedOrderId.HasValue)
                    {
                        bodyBuilder.AppendLine($"Order: #{task.LinkedOrderId.Value}");
                    }
                    if (!string.IsNullOrWhiteSpace(task.Notes))
                    {
                        bodyBuilder.AppendLine(task.Notes.Trim());
                    }
                    else
                    {
                        bodyBuilder.AppendLine("Task is due now.");
                    }

                    var payload = new Dictionary<string, string>
                    {
                        ["type"] = "scheduled_task_reminder",
                        ["taskId"] = task.Id.ToString(),
                        ["companyId"] = task.CompanyId.ToString(),
                        ["title"] = string.IsNullOrWhiteSpace(task.Title) ? "FLORAPRISE TASK REMINDER" : task.Title,
                        ["body"] = bodyBuilder.ToString().Trim(),
                        ["scheduledAtUtc"] = task.ScheduledAt.ToString("O"),
                        ["priority"] = task.Priority ?? "normal",
                        ["requiresAlarm"] = task.RequiresAlarm ? "true" : "false",
                        ["requiresConfirmation"] = task.RequiresConfirmation ? "true" : "false"
                    };

                    var tokens = targetDevices.Select(d => d.PushToken!).Distinct();
                    await fcmService.SendDataNotificationMulticastAsync(tokens, payload, cancellationToken);
                }

                // Advance NextReminderAt by 15 minutes so the reminder does not spam in a 30-second loop
                task.Update(
                    task.Title,
                    task.Type,
                    task.Category,
                    task.Priority ?? "normal",
                    task.ScheduledAt,
                    utcNow.AddMinutes(15),
                    task.DeadlineAt,
                    task.Notes,
                    task.LinkedCustomerId,
                    task.LinkedOrderId,
                    task.AssignedStaffId,
                    task.RequiresConfirmation,
                    task.RequiresAlarm);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing reminder for task {TaskId}.", task.Id);
            }
        }

        await db.SaveChangesAsync(cancellationToken);
    }
}
