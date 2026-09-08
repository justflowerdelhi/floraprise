using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;
using Sumpooj.Infrastructure.Repositories;
using Xunit;

namespace Sumpooj.Infrastructure.Tests.Repositories;

public class StaffRepositoryAssignmentTests
{
    [Fact]
    public async Task GetByRoleAsync_DesignerReturnsStaffIdWithoutRequiringAnIdentityUser()
    {
        var companyId = Guid.NewGuid();
        await using var context = CreateInMemoryContext(companyId);
        var designer = CreateStaff(companyId, "Asha Designer", StaffRole.Designer);
        context.Staff.Add(designer);
        await context.SaveChangesAsync();

        var result = await new StaffRepository(context).GetByRoleAsync(companyId, "Designer");

        var assignee = Assert.Single(result);
        Assert.Equal(designer.Id, assignee.Id);
    }

    [Fact]
    public async Task GetByRoleAsync_ReturnsActiveDesignerWithoutIdentityAccount()
    {
        var companyId = Guid.NewGuid();
        await using var context = CreateInMemoryContext(companyId);
        context.Staff.Add(CreateStaff(companyId, "Designer Without Login", StaffRole.Designer));
        await context.SaveChangesAsync();

        var result = await new StaffRepository(context).GetByRoleAsync(companyId, "Designer");

        Assert.Equal("Designer Without Login", Assert.Single(result).Name);
    }

    [Fact]
    public async Task GetAvailableDriversAsync_ReturnsStaffIdWithoutRequiringAnIdentityAccount()
    {
        var companyId = Guid.NewGuid();
        await using var context = CreateInMemoryContext(companyId);
        var driver = CreateStaff(companyId, "Bhanu Driver", StaffRole.Driver);
        context.Staff.Add(driver);
        await context.SaveChangesAsync();

        var result = await new StaffRepository(context).GetAvailableDriversAsync(companyId);

        var assignee = Assert.Single(result);
        Assert.Equal(driver.Id, assignee.Id);
    }

    [Fact]
    public async Task GetAvailableDriversAsync_ExcludesInactiveAndNonDriverStaff()
    {
        var companyId = Guid.NewGuid();
        await using var context = CreateInMemoryContext(companyId);
        var activeDriver = CreateStaff(companyId, "Active Driver", StaffRole.Driver);
        var inactiveDriver = CreateStaff(companyId, "Inactive Driver", StaffRole.Driver);
        inactiveDriver.Deactivate();
        var designer = CreateStaff(companyId, "Active Designer", StaffRole.Designer);
        context.Staff.AddRange(activeDriver, inactiveDriver, designer);
        await context.SaveChangesAsync();

        var result = await new StaffRepository(context).GetAvailableDriversAsync(companyId);

        var assignee = Assert.Single(result);
        Assert.Equal(activeDriver.Id, assignee.Id);
    }

    [Fact]
    public async Task GetByRoleAsync_IsCompanyScopedAndOrderedByName()
    {
        var companyId = Guid.NewGuid();
        var otherCompanyId = Guid.NewGuid();
        await using var context = CreateInMemoryContext(companyId);
        var zara = CreateStaff(companyId, "Zara Designer", StaffRole.Designer);
        var asha = CreateStaff(companyId, "Asha Designer", StaffRole.Designer);
        var other = CreateStaff(otherCompanyId, "Other Designer", StaffRole.Designer);
        context.Staff.AddRange(zara, asha, other);
        await context.SaveChangesAsync();

        var result = await new StaffRepository(context).GetByRoleAsync(companyId, "Designer");

        Assert.Equal(["Asha Designer", "Zara Designer"], result.Select(s => s.Name));
        Assert.Equal([asha.Id, zara.Id], result.Select(s => s.Id));
    }

    private static Staff CreateStaff(Guid companyId, string name, StaffRole role) =>
        new(companyId, name, role, $"{name}@example.com", "9876543210", null);

    private static SumpoojDbContext CreateInMemoryContext(Guid companyId)
    {
        var options = new DbContextOptionsBuilder<SumpoojDbContext>()
            .UseInMemoryDatabase($"StaffRepositoryAssignment_{Guid.NewGuid():N}")
            .Options;
        return new SumpoojDbContext(options, new TenantContext(companyId));
    }

    private sealed class TenantContext(Guid companyId) : ITenantContext
    {
        public Guid? CompanyId => companyId;
        public bool IsPlatformUser => false;
        public string? Region => null;
    }
}