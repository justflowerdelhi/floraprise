using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Infrastructure.ExternalServices;

public class TaskAssignmentNotificationService : ITaskAssignmentNotificationService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<TaskAssignmentNotificationService> _logger;

    public TaskAssignmentNotificationService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<TaskAssignmentNotificationService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task NotifyTaskAssignedAsync(
        string staffName,
        string? staffPhone,
        string taskTitle,
        string? taskDescription,
        string taskPriority,
        DateTime? dueDate,
        bool isReassignment)
    {
        if (string.IsNullOrWhiteSpace(staffPhone))
        {
            _logger.LogInformation(
                "Skipping task assignment notification because phone is missing for staff {StaffName}",
                staffName);
            return;
        }

        var webhookUrl = _configuration["Notifications:TaskAssignmentWebhookUrl"]
            ?? _configuration["Arattai:WebhookUrl"];

        if (string.IsNullOrWhiteSpace(webhookUrl))
        {
            _logger.LogInformation("Task assignment webhook URL is not configured. Skipping notification.");
            return;
        }

        var action = isReassignment ? "Task Reassigned" : "New Task Assigned";
        var dueText = dueDate.HasValue
            ? (dueDate.Value.Kind == DateTimeKind.Utc
                ? dueDate.Value.ToString("yyyy-MM-dd HH:mm 'UTC'")
                : dueDate.Value.ToUniversalTime().ToString("yyyy-MM-dd HH:mm 'UTC'"))
            : "No due date";

        var message = $"""
            {action}
            Staff: {staffName}
            Task: {taskTitle}
            Priority: {taskPriority}
            Due: {dueText}
            Description: {taskDescription ?? "-"}
            """;

        var payload = new
        {
            phone = staffPhone,
            to = staffPhone,
            message,
            text = message,
            staffName,
            taskTitle,
            taskPriority,
            dueDateUtc = dueDate?.ToUniversalTime()
        };

        var json = JsonSerializer.Serialize(payload);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        try
        {
            var client = _httpClientFactory.CreateClient();
            var response = await client.PostAsync(webhookUrl, content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation(
                    "Task assignment notification sent to {Phone} for task {TaskTitle}",
                    staffPhone,
                    taskTitle);
                return;
            }

            var body = await response.Content.ReadAsStringAsync();
            _logger.LogWarning(
                "Task assignment webhook returned {StatusCode}: {Body}",
                (int)response.StatusCode,
                body);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(
                ex,
                "Failed to send task assignment notification to {Phone} for task {TaskTitle}",
                staffPhone,
                taskTitle);
        }
    }
}