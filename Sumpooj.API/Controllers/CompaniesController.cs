using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Companies;
using Sumpooj.Infrastructure;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/platform/companies")]
[Authorize(Policy = PolicyNames.PlatformSupport)]
public class CompaniesController : ControllerBase
{
    private readonly ICompanyService _service;
    private readonly SumpoojDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;

    public CompaniesController(
        ICompanyService service,
        SumpoojDbContext db,
        UserManager<ApplicationUser> userManager)
    {
        _service = service;
        _db = db;
        _userManager = userManager;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var companies = await _service.GetAllAsync();
        return Ok(companies);
    }

    [HttpGet("{companyId:guid}")]
    public async Task<IActionResult> GetById(Guid companyId)
    {
        var company = await _service.GetByIdAsync(companyId);
        return company == null ? NotFound() : Ok(company);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateCompanyRequest request)
    {
        var companyId = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { companyId }, companyId);
    }

    [HttpPut("{companyId:guid}")]
    public async Task<IActionResult> Update(Guid companyId, CreateCompanyRequest request)
    {
        // Reuse CreateCompanyRequest for update (same fields)
        var existing = await _service.GetByIdAsync(companyId);
        if (existing == null) return NotFound();

        await _service.UpdateSettingsAsync(companyId, new UpdateCompanySettingsRequest
        {
            TimeZone = request.TimeZone,
            CurrencyCode = request.CurrencyCode,
            TaxIdentifier = request.TaxIdentifier,
        });
        return NoContent();
    }

    [HttpPatch("{companyId:guid}/activate")]
    public async Task<IActionResult> Activate(Guid companyId)
    {
        await _service.SetActiveAsync(companyId, true);
        return NoContent();
    }

    [HttpPatch("{companyId:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid companyId)
    {
        await _service.SetActiveAsync(companyId, false);
        return NoContent();
    }

    /// <summary>
    /// Populate ~5 demo records per major table for a company.
    /// Platform Super Admin only. Skips tables that already have data.
    /// </summary>
    [HttpPost("{companyId:guid}/seed-demo-data")]
    [Authorize(Policy = PolicyNames.PlatformOnly)]
    public async Task<IActionResult> SeedDemoData(Guid companyId)
    {
        var result = await CompanyDemoDataSeeder.SeedAsync(_db, companyId);
        return Ok(result);
    }

    /// <summary>
    /// Remove ALL company data from every major table (for going live).
    /// The Company record itself is preserved — only its data is wiped.
    /// Platform Super Admin only.
    /// </summary>
    [HttpPost("{companyId:guid}/purge-demo-data")]
    [Authorize(Policy = PolicyNames.PlatformOnly)]
    public async Task<IActionResult> PurgeDemoData(Guid companyId)
    {
        var result = await CompanyDemoDataSeeder.PurgeAsync(_db, companyId);
        return Ok(result);
    }

    /// <summary>
    /// Get login credentials for a company's admin user.
    /// Resets the password to a new temporary value each time.
    /// Platform Super Admin only.
    /// </summary>
    [HttpPost("{companyId:guid}/admin-credentials")]
    [Authorize(Policy = PolicyNames.PlatformOnly)]
    public async Task<IActionResult> GetAdminCredentials(Guid companyId)
    {
        var company = await _service.GetByIdAsync(companyId);
        if (company == null) return NotFound(new { message = "Company not found." });

        // Find the CompanyAdmin user for this company
        var adminUsers = await _userManager.Users
            .Where(u => u.CompanyId == companyId)
            .ToListAsync();

        ApplicationUser? adminUser = null;
        foreach (var user in adminUsers)
        {
            if (await _userManager.IsInRoleAsync(user, "CompanyAdmin"))
            {
                adminUser = user;
                break;
            }
        }

        if (adminUser == null)
            return NotFound(new { message = "No CompanyAdmin user found for this company." });

        // Generate a new temp password and reset
        var tempPassword = GenerateTempPassword();
        var resetToken = await _userManager.GeneratePasswordResetTokenAsync(adminUser);
        var resetResult = await _userManager.ResetPasswordAsync(adminUser, resetToken, tempPassword);

        if (!resetResult.Succeeded)
        {
            var errors = string.Join(", ", resetResult.Errors.Select(e => e.Description));
            return BadRequest(new { message = $"Failed to reset password: {errors}" });
        }

        return Ok(new
        {
            companyName = company.Name,
            adminEmail = adminUser.Email,
            tempPassword,
        });
    }

    private static string GenerateTempPassword()
    {
        const string upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
        const string lower = "abcdefghjkmnpqrstuvwxyz";
        const string digits = "23456789";
        var rng = Random.Shared;
        return $"Flora@{upper[rng.Next(upper.Length)]}{lower[rng.Next(lower.Length)]}{digits[rng.Next(digits.Length)]}{lower[rng.Next(lower.Length)]}{digits[rng.Next(digits.Length)]}{upper[rng.Next(upper.Length)]}";
    }
}
