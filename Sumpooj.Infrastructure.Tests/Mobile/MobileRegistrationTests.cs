using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sumpooj.API.Controllers.Mobile;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Sumpooj.Infrastructure.Companies;

namespace Sumpooj.Infrastructure.Tests.Mobile;

public class MobileRegistrationTests : IDisposable
{
    private readonly SumpoojDbContext _db;
    private readonly ServiceProvider _serviceProvider;
    private readonly MobileAuthController _controller;

    public MobileRegistrationTests()
    {
        var services = new ServiceCollection();
        
        services.AddLogging();
        services.AddDbContext<SumpoojDbContext>(options =>
            options.UseInMemoryDatabase("TestDb_" + Guid.NewGuid()));
        
        services.AddScoped<MobileCustomerRepository>();
        services.AddScoped<MobileUserRepository>();
        services.AddScoped<MobileDeviceRepository>();
        services.AddScoped<MobileSubscriptionRepository>();
        services.AddScoped<MobileLicenseRepository>();
        services.AddScoped<DeviceSessionRepository>();
        services.AddScoped<CompanyService>();
        services.AddScoped<MobileSubscriptionService>();
        services.AddScoped<MobileClientService>();
        services.AddScoped<MobileAuthController>();
        
        _serviceProvider = services.BuildServiceProvider();
        _db = _serviceProvider.GetRequiredService<SumpoojDbContext>();
        _controller = _serviceProvider.GetRequiredService<MobileAuthController>();
        
        _db.Database.EnsureCreated();
    }

    public void Dispose()
    {
        _db.Database.EnsureDeleted();
        _db.Dispose();
        _serviceProvider.Dispose();
    }

    [Fact]
    public async Task Registration_ShouldSucceed_WithValidData()
    {
        // Arrange
        var request = new MobileApiRegisterRequest
        {
            CompanyName = "Test Company",
            OwnerName = "Test Owner",
            Mobile = "9876543210",
            Email = "test@example.com",
            Password = "Test@123456",
            Address = "Test Address",
            DeviceId = "test-device-001",
            Platform = "Android",
            Manufacturer = "Samsung",
            Model = "Galaxy S21",
            OsVersion = "12",
            AppVersion = "1.0.0",
            PushToken = "push-token-123",
            IpAddress = "127.0.0.1"
        };

        // Act
        var result = await _controller.Register(request, CancellationToken.None);

        // Assert
        var okResult = Assert.IsType<OkObjectResult>(result);
        Assert.NotNull(okResult.Value);
        
        // Verify all entities were created
        var company = await _db.Companies.FirstOrDefaultAsync(c => c.Email == request.Email);
        Assert.NotNull(company);
        
        var mobileCustomer = await _db.MobileCustomers.FirstOrDefaultAsync(c => c.Mobile == request.Mobile);
        Assert.NotNull(mobileCustomer);
        
        var mobileUser = await _db.MobileUsers.FirstOrDefaultAsync(u => u.Mobile == request.Mobile);
        Assert.NotNull(mobileUser);
        
        var mobileDevice = await _db.MobileDevices.FirstOrDefaultAsync(d => d.DeviceId == request.DeviceId);
        Assert.NotNull(mobileDevice);
        
        var subscription = await _db.MobileSubscriptions.FirstOrDefaultAsync(s => s.MobileUserId == mobileUser.Id);
        Assert.NotNull(subscription);
        
        var license = await _db.MobileLicenses.FirstOrDefaultAsync(l => l.MobileDeviceId == mobileDevice.Id);
        Assert.NotNull(license);
    }

    [Fact]
    public async Task Registration_ShouldFail_WithDuplicateEmail()
    {
        // Arrange - Create initial registration
        var request1 = new MobileApiRegisterRequest
        {
            CompanyName = "Test Company 1",
            OwnerName = "Test Owner 1",
            Mobile = "9876543210",
            Email = "duplicate@example.com",
            Password = "Test@123456",
            Address = "Test Address",
            DeviceId = "test-device-001",
            Platform = "Android",
            Manufacturer = "Samsung",
            Model = "Galaxy S21",
            OsVersion = "12",
            AppVersion = "1.0.0"
        };

        await _controller.Register(request1, CancellationToken.None);

        // Act - Try to register with same email
        var request2 = new MobileApiRegisterRequest
        {
            CompanyName = "Test Company 2",
            OwnerName = "Test Owner 2",
            Mobile = "9876543211",
            Email = "duplicate@example.com",
            Password = "Test@123456",
            Address = "Test Address",
            DeviceId = "test-device-002",
            Platform = "Android",
            Manufacturer = "Samsung",
            Model = "Galaxy S21",
            OsVersion = "12",
            AppVersion = "1.0.0"
        };

        var result = await _controller.Register(request2, CancellationToken.None);

        // Assert
        var conflictResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(409, conflictResult.StatusCode);
    }

    [Fact]
    public async Task Registration_ShouldFail_WithDuplicatePhone()
    {
        // Arrange - Create initial registration
        var request1 = new MobileApiRegisterRequest
        {
            CompanyName = "Test Company 1",
            OwnerName = "Test Owner 1",
            Mobile = "9876543210",
            Email = "test1@example.com",
            Password = "Test@123456",
            Address = "Test Address",
            DeviceId = "test-device-001",
            Platform = "Android",
            Manufacturer = "Samsung",
            Model = "Galaxy S21",
            OsVersion = "12",
            AppVersion = "1.0.0"
        };

        await _controller.Register(request1, CancellationToken.None);

        // Act - Try to register with same phone
        var request2 = new MobileApiRegisterRequest
        {
            CompanyName = "Test Company 2",
            OwnerName = "Test Owner 2",
            Mobile = "9876543210",
            Email = "test2@example.com",
            Password = "Test@123456",
            Address = "Test Address",
            DeviceId = "test-device-002",
            Platform = "Android",
            Manufacturer = "Samsung",
            Model = "Galaxy S21",
            OsVersion = "12",
            AppVersion = "1.0.0"
        };

        var result = await _controller.Register(request2, CancellationToken.None);

        // Assert
        var conflictResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(409, conflictResult.StatusCode);
    }

    [Fact]
    public async Task Registration_ShouldFail_WithMissingRequiredFields()
    {
        // Arrange
        var request = new MobileApiRegisterRequest
        {
            CompanyName = "", // Missing
            OwnerName = "", // Missing
            Mobile = "", // Missing
            Email = "", // Missing
            Password = "", // Missing
            DeviceId = "test-device-001",
            Platform = "Android",
            AppVersion = "1.0.0"
        };

        // Act
        var result = await _controller.Register(request, CancellationToken.None);

        // Assert
        var badRequestResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(400, badRequestResult.StatusCode);
    }

    [Fact]
    public async Task Registration_ShouldRollback_WhenTransactionFails()
    {
        // Arrange
        var request = new MobileApiRegisterRequest
        {
            CompanyName = "Test Company",
            OwnerName = "Test Owner",
            Mobile = "9876543210",
            Email = "test@example.com",
            Password = "Test@123456",
            Address = "Test Address",
            DeviceId = "", // Invalid - should cause failure
            Platform = "Android",
            AppVersion = "1.0.0"
        };

        // Get initial company count
        var initialCompanyCount = await _db.Companies.CountAsync();

        // Act
        var result = await _controller.Register(request, CancellationToken.None);

        // Assert - Should fail
        var badRequestResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(400, badRequestResult.StatusCode);

        // Verify no orphan records exist
        var finalCompanyCount = await _db.Companies.CountAsync();
        Assert.Equal(initialCompanyCount, finalCompanyCount);
        
        var mobileCustomer = await _db.MobileCustomers.FirstOrDefaultAsync(c => c.Mobile == request.Mobile);
        Assert.Null(mobileCustomer);
    }
}
