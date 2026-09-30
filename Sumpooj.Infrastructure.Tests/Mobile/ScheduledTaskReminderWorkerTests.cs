using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Workers;

namespace Sumpooj.Infrastructure.Tests.Mobile;

public class ScheduledTaskReminderWorkerTests : IDisposable
{
    private readonly SumpoojDbContext _db;
    private readonly TestFcmNotificationService _fcmService;
    private readonly IServiceProvider _serviceProvider;

    public ScheduledTaskReminderWorkerTests()
    {
        var dbName = $"ScheduledTaskReminder_{Guid.NewGuid():N}";
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase(dbName)
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;

        _db = new SumpoojDbContext(options, new TestTenantContext(null));
        _fcmService = new TestFcmNotificationService();

        var services = new ServiceCollection();
        services.AddScoped(_ => new SumpoojDbContext(options, new TestTenantContext(null)));
        services.AddSingleton<IFcmNotificationService>(_fcmService);

        _serviceProvider = services.BuildServiceProvider();
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task ProcessDueTasks_DispatchesFCM_ForDueTasks_AndAdvancesNextReminderAt()
    {
        var companyId = Guid.NewGuid();
        var mobileUserId = Guid.NewGuid();

        // Register active device with push token
        var device = new MobileDevice(
            companyId,
            mobileUserId,
            Guid.NewGuid(),
            "device-001",
            "Google",
            "Pixel 8",
            "ANDROID",
            "14",
            "1.0.0",
            "fcm-token-test-123");
        await _db.MobileDevices.AddAsync(device);

        // Add due task
        var task = new SchedulerRecord(companyId, "manual", "ref-1");
        task.Update(
            "Call Priya for Wedding Bouquet",
            "reminder",
            "operational",
            "urgent",
            DateTime.UtcNow.AddMinutes(-5),
            null,
            null,
            "Urgent follow up required",
            null,
            null,
            null,
            true,
            true);
        await _db.SchedulerRecords.AddAsync(task);
        await _db.SaveChangesAsync();

        var worker = new ScheduledTaskReminderWorker(_serviceProvider, NullLogger<ScheduledTaskReminderWorker>.Instance);

        // Trigger processing cycle via private/internal or ExecuteAsync
        var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));
        var workerTask = worker.StartAsync(cts.Token);
        await Task.Delay(500);
        await worker.StopAsync(CancellationToken.None);

        // Verify notification dispatched
        Assert.NotEmpty(_fcmService.DispatchedData);
        var lastDispatch = _fcmService.DispatchedData.Last();

        Assert.Equal("scheduled_task_reminder", lastDispatch["type"]);
        Assert.Equal(task.Id.ToString(), lastDispatch["taskId"]);
        Assert.Equal(companyId.ToString(), lastDispatch["companyId"]);
        Assert.Equal("Call Priya for Wedding Bouquet", lastDispatch["title"]);
        Assert.Equal("urgent", lastDispatch["priority"]);
        Assert.Equal("true", lastDispatch["requiresAlarm"]);

        // Verify task NextReminderAt was advanced
        using var verifyScope = _serviceProvider.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<SumpoojDbContext>();
        var updatedTask = await verifyDb.SchedulerRecords.AsNoTracking().FirstOrDefaultAsync(x => x.Id == task.Id);
        Assert.NotNull(updatedTask?.NextReminderAt);
        Assert.True(updatedTask!.NextReminderAt > DateTime.UtcNow);
    }

    [Fact]
    public async Task ProcessDueTasks_DoesNotDispatch_ForFutureOrCompletedTasks()
    {
        var companyId = Guid.NewGuid();
        var mobileUserId = Guid.NewGuid();

        var device = new MobileDevice(
            companyId,
            mobileUserId,
            Guid.NewGuid(),
            "device-002",
            "Samsung",
            "S24",
            "ANDROID",
            "14",
            "1.0.0",
            "fcm-token-test-456");
        await _db.MobileDevices.AddAsync(device);

        // Future task
        var futureTask = new SchedulerRecord(companyId, "manual", "ref-future");
        futureTask.Update(
            "Future Task Tomorrow",
            "reminder",
            "operational",
            "normal",
            DateTime.UtcNow.AddHours(24),
            null,
            null,
            "Not due yet",
            null,
            null,
            null,
            false,
            false);
        await _db.SchedulerRecords.AddAsync(futureTask);

        // Completed task
        var completedTask = new SchedulerRecord(companyId, "manual", "ref-comp");
        completedTask.Update(
            "Completed Task",
            "reminder",
            "operational",
            "normal",
            DateTime.UtcNow.AddHours(-1),
            null,
            null,
            "Already done",
            null,
            null,
            null,
            false,
            false);
        completedTask.SetStatus("completed");
        await _db.SchedulerRecords.AddAsync(completedTask);
        await _db.SaveChangesAsync();

        var worker = new ScheduledTaskReminderWorker(_serviceProvider, NullLogger<ScheduledTaskReminderWorker>.Instance);
        var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));
        await worker.StartAsync(cts.Token);
        await Task.Delay(500);
        await worker.StopAsync(CancellationToken.None);

        Assert.Empty(_fcmService.DispatchedData);
    }

    [Fact]
    public async Task ProcessDueTasks_RespectsTenantIsolation()
    {
        var companyA = Guid.NewGuid();
        var companyB = Guid.NewGuid();

        var deviceA = new MobileDevice(companyA, Guid.NewGuid(), Guid.NewGuid(), "dev-A", "Google", "Pixel", "ANDROID", "14", "1.0.0", "fcm-token-A");
        var deviceB = new MobileDevice(companyB, Guid.NewGuid(), Guid.NewGuid(), "dev-B", "Google", "Pixel", "ANDROID", "14", "1.0.0", "fcm-token-B");
        await _db.MobileDevices.AddRangeAsync(deviceA, deviceB);

        var taskA = new SchedulerRecord(companyA, "manual", "ref-A");
        taskA.Update("Company A Task", "reminder", "operational", "normal", DateTime.UtcNow.AddMinutes(-1), null, null, "A notes", null, null, null, false, false);
        await _db.SchedulerRecords.AddAsync(taskA);
        await _db.SaveChangesAsync();

        var worker = new ScheduledTaskReminderWorker(_serviceProvider, NullLogger<ScheduledTaskReminderWorker>.Instance);
        var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));
        await worker.StartAsync(cts.Token);
        await Task.Delay(500);
        await worker.StopAsync(CancellationToken.None);

        // Verify only device A received notification
        Assert.Single(_fcmService.DispatchedTokens);
        Assert.Equal("fcm-token-A", _fcmService.DispatchedTokens.First());
    }

    private sealed class TestFcmNotificationService : IFcmNotificationService
    {
        public List<string> DispatchedTokens { get; } = new();
        public List<IDictionary<string, string>> DispatchedData { get; } = new();

        public Task<bool> SendDataNotificationAsync(string pushToken, IDictionary<string, string> data, CancellationToken cancellationToken = default)
        {
            DispatchedTokens.Add(pushToken);
            DispatchedData.Add(data);
            return Task.FromResult(true);
        }

        public Task<int> SendDataNotificationMulticastAsync(IEnumerable<string> pushTokens, IDictionary<string, string> data, CancellationToken cancellationToken = default)
        {
            var list = pushTokens.ToList();
            DispatchedTokens.AddRange(list);
            DispatchedData.Add(data);
            return Task.FromResult(list.Count);
        }
    }

    private sealed class TestTenantContext(Guid? companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => companyId == null;
        public string? Region => null;
    }
}
