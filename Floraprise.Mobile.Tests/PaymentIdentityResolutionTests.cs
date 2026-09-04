using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Controllers;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Payments;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Floraprise.Mobile.Tests;

public sealed class PaymentIdentityResolutionTests : IDisposable
{
    private readonly SumpoojDbContext _db;
    private readonly Guid _companyId = Guid.NewGuid();
    private readonly Guid _orderId;

    public PaymentIdentityResolutionTests()
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"PaymentIdentity_{Guid.NewGuid():N}")
            .Options;
        _db = new SumpoojDbContext(options, new TestTenantContext(_companyId));
        var customer = new Customer(_companyId, "Test Customer", null, "9999999999");
        var order = new Order(_companyId, customer.Id, DateTime.UtcNow, null, null, null, null);
        _orderId = order.Id;
        _db.AddRange(customer, order);
        _db.SaveChanges();
    }

    public void Dispose() => _db.Dispose();

    [Fact]
    public async Task CreatePayment_UsesIdentityUserIdForMobileToken()
    {
        var mobileUserId = Guid.NewGuid();
        var identityUserId = Guid.NewGuid();
        var controller = CreateController(Principal(
            new Claim("client_type", "mobile"),
            new Claim("mobile_user_id", mobileUserId.ToString()),
            new Claim("identity_user_id", identityUserId.ToString()),
            new Claim(ClaimTypes.NameIdentifier, mobileUserId.ToString())));

        var result = await controller.Create(new CreatePaymentRequest
        {
            OrderId = _orderId,
            Method = "Cash",
            Amount = 100m
        });

        Assert.IsType<CreatedAtActionResult>(result);
        var payment = await _db.Payments.SingleAsync();
        Assert.NotEqual(mobileUserId, identityUserId);
        Assert.Equal(identityUserId, payment.ProcessedByUserId);
    }

    [Fact]
    public async Task CreatePayment_RejectsOldMobileTokenWithoutIdentityUserId()
    {
        var mobileUserId = Guid.NewGuid();
        var controller = CreateController(Principal(
            new Claim("client_type", "mobile"),
            new Claim("mobile_user_id", mobileUserId.ToString()),
            new Claim(ClaimTypes.NameIdentifier, mobileUserId.ToString())));

        var result = await controller.Create(new CreatePaymentRequest
        {
            OrderId = _orderId,
            Method = "Cash",
            Amount = 100m
        });

        Assert.IsType<UnauthorizedObjectResult>(result);
        Assert.Empty(_db.Payments);
    }

    [Fact]
    public async Task CreatePayment_UsesNameIdentifierForLegacyToken()
    {
        var identityUserId = Guid.NewGuid();
        var controller = CreateController(Principal(new Claim(ClaimTypes.NameIdentifier, identityUserId.ToString())));

        var result = await controller.Create(new CreatePaymentRequest
        {
            OrderId = _orderId,
            Method = "Cash",
            Amount = 100m
        });

        Assert.IsType<CreatedAtActionResult>(result);
        Assert.Equal(identityUserId, (await _db.Payments.SingleAsync()).ProcessedByUserId);
    }

    private PaymentsController CreateController(ClaimsPrincipal user)
    {
        var payments = new PaymentRepository(_db);
        var orders = new OrderRepository(_db);
        return new PaymentsController(new PaymentService(payments, orders), new TestTenantContext(_companyId), null!)
        {
            ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext { User = user } }
        };
    }

    private static ClaimsPrincipal Principal(params Claim[] claims) => new(new ClaimsIdentity(claims, "test"));

    private sealed class TestTenantContext : ITenantContext
    {
        public TestTenantContext(Guid companyId) => CompanyId = companyId;
        public Guid? CompanyId { get; }
        public string? Region => null;
        public bool IsPlatformUser => false;
    }
}
