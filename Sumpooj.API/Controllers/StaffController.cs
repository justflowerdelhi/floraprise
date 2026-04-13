using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Staff;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "CompanyOnly")]
public class StaffController : ControllerBase
{
    private readonly ILogger<StaffController> _logger;
    private readonly IWebHostEnvironment _environment;
    private readonly StaffService _staffService;
    private readonly ITenantContext _tenantContext;
    private readonly IOrderRepository _orderRepo;
    private readonly IDeliveryRepository _deliveryRepo;

    public StaffController(
        ILogger<StaffController> logger,
        IWebHostEnvironment environment,
        StaffService staffService,
        ITenantContext tenantContext,
        IOrderRepository orderRepo,
        IDeliveryRepository deliveryRepo)
    {
        _logger = logger;
        _environment = environment;
        _staffService = staffService;
        _tenantContext = tenantContext;
        _orderRepo = orderRepo;
        _deliveryRepo = deliveryRepo;
    }

    private Guid CompanyId => _tenantContext.CompanyId 
        ?? throw new UnauthorizedAccessException("Company context required");

    private static string GetInnermostMessage(Exception ex)
    {
        var current = ex;
        while (current.InnerException != null)
        {
            current = current.InnerException;
        }

        return current.Message;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var staff = await _staffService.GetAllActiveAsync(CompanyId);
        return Ok(staff);
    }

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] StaffSearchRequest request)
    {
        var result = await _staffService.SearchAsync(CompanyId, request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var staff = await _staffService.GetByIdAsync(CompanyId, id);
        return staff == null ? NotFound() : Ok(staff);
    }

    [HttpGet("by-role/{role}")]
    public async Task<IActionResult> GetByRole(string role)
    {
        var staff = await _staffService.GetByRoleAsync(CompanyId, role);
        return Ok(staff);
    }

    [HttpGet("available-drivers")]
    public async Task<IActionResult> GetAvailableDrivers()
    {
        var drivers = await _staffService.GetAvailableDriversAsync(CompanyId);
        return Ok(drivers.Select(s => new { id = s.Id, name = s.Name, driverStatus = s.DriverStatus }));
    }

    [HttpPost]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Create([FromBody] CreateStaffRequest request)
    {
        try
        {
            var result = await _staffService.CreateAsync(CompanyId, request);
            return CreatedAtAction(nameof(GetById), new { id = result.StaffId }, new { id = result.StaffId });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create staff for company {CompanyId}. Name={Name}, Role={Role}", CompanyId, request.Name, request.Role);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to create staff member. Please try again later."
            });
        }
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateStaffRequest request)
    {
        try
        {
            await _staffService.UpdateAsync(CompanyId, id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update staff {StaffId} for company {CompanyId}", id, CompanyId);
            return StatusCode(500, new
            {
                error = _environment.IsDevelopment()
                    ? GetInnermostMessage(ex)
                    : "Failed to update staff member. Please try again later."
            });
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        await _staffService.DeactivateAsync(CompanyId, id);
        return NoContent();
    }

    // ── Login management endpoints ───────────────────────────

    [HttpPost("{id:guid}/enable-login")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> EnableLogin(Guid id, [FromBody] EnableLoginRequest request)
    {
        await _staffService.EnableLoginAsync(CompanyId, id, request);
        return NoContent();
    }

    [HttpPost("{id:guid}/reset-password")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> ResetPassword(Guid id, [FromBody] ResetPasswordRequest request)
    {
        await _staffService.ResetPasswordAsync(CompanyId, id, request.Password);
        return NoContent();
    }

    [HttpPost("{id:guid}/disable-login")]
    [Authorize(Policy = "CompanyAdmin")]
    public async Task<IActionResult> DisableLogin(Guid id)
    {
        await _staffService.DisableLoginAsync(CompanyId, id);
        return NoContent();
    }

    // ── Performance endpoint ─────────────────────────────────

    [HttpGet("{id:guid}/has-orders")]
    public async Task<IActionResult> HasOrders(Guid id)
    {
        var count = await _orderRepo.GetOrderCountByStaffAsync(CompanyId, id, DateTime.MinValue, DateTime.MaxValue);
        return Ok(new { hasOrders = count > 0, orderCount = count });
    }

    [HttpGet("{id:guid}/performance")]
    public async Task<IActionResult> GetPerformance(
        Guid id,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to)
    {
        var staff = await _staffService.GetByIdAsync(CompanyId, id);
        if (staff == null) return NotFound();

        var periodStart = from ?? DateTime.Today.AddDays(-30);
        var periodEnd = to ?? DateTime.Today.AddDays(1);

        // Sales metrics
        var orderCount = await _orderRepo.GetOrderCountByStaffAsync(CompanyId, id, periodStart, periodEnd);
        var revenue = await _orderRepo.GetRevenueByCashierAsync(CompanyId, id, periodStart, periodEnd);
        var avgOrder = orderCount > 0 ? revenue / orderCount : 0;
        var grossProfit = revenue * 0.35m; // simplified

        // Delivery metrics
        var deliveriesAssigned = await _deliveryRepo.GetDeliveryCountByDriverAsync(id, periodStart, periodEnd);
        var deliveriesCompleted = await _deliveryRepo.GetCompletedDeliveryCountByDriverAsync(id, periodStart, periodEnd);
        var onTimeRate = deliveriesAssigned > 0 ? (decimal)deliveriesCompleted / deliveriesAssigned * 100 : 0;

        var result = new StaffPerformanceDto
        {
            StaffId = id,
            StaffName = staff.Name,
            StaffRole = staff.Role,
            PeriodStart = periodStart.ToString("yyyy-MM-dd"),
            PeriodEnd = periodEnd.ToString("yyyy-MM-dd"),
            Sales = new SalesMetricsDto
            {
                TotalOrders = orderCount,
                TotalRevenue = revenue,
                GrossProfit = grossProfit,
                MarginPercent = revenue > 0 ? grossProfit / revenue * 100 : 0,
                AverageOrderValue = avgOrder,
            },
            Deliveries = new DeliveryMetricsDto
            {
                DeliveriesAssigned = deliveriesAssigned,
                DeliveriesCompleted = deliveriesCompleted,
                DeliveriesOnTime = deliveriesCompleted,
                OnTimeRate = onTimeRate,
            },
        };

        return Ok(result);
    }
}
