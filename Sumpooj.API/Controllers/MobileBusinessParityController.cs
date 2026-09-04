using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.API.Controllers;

public record SaveOccasionContactRequest(Guid CustomerId, string RecipientName, string Relationship, string Occasion,
    DateTime OccasionDate, string? RecipientPhone, string? Company, string? Notes, bool ReminderEnabled, string Source);
public record SnoozeOccasionRequest(DateTime SnoozedTo);
public record SaveSchedulerRecordRequest(string Title, string Type, string Category, string Priority, DateTime ScheduledAt,
    DateTime? NextReminderAt, DateTime? DeadlineAt, string? Notes, Guid? LinkedCustomerId, Guid? LinkedOrderId,
    Guid? AssignedStaffId, string Producer, string SourceRef, bool RequiresConfirmation, bool RequiresAlarm);
public record SetSchedulerStatusRequest(string Status);
public record SaveCloudDesignRequest(string Description, string? ImageReference, int? SellingPricePaise, string? Flowers,
    string? Occasion, string? Color, string? Collection, string? Notes, bool IsFavorite);

public abstract class MobileParityControllerBase : ControllerBase
{
    protected readonly SumpoojDbContext Db;
    private readonly ITenantContext _tenant;
    protected MobileParityControllerBase(SumpoojDbContext db, ITenantContext tenant) { Db = db; _tenant = tenant; }
    protected Guid CompanyId => _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");
}

[ApiController, Route("api/occasion-contacts"), Authorize(Policy = "CompanyOnly")]
public class OccasionContactsController : MobileParityControllerBase
{
    public OccasionContactsController(SumpoojDbContext db, ITenantContext tenant) : base(db, tenant) { }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid? customerId, [FromQuery] DateTime? from, [FromQuery] DateTime? to,
        [FromQuery] string? occasion, [FromQuery] string? query)
    {
        var rows = Db.OccasionContacts.Where(x => x.CompanyId == CompanyId && x.DeletedAtUtc == null);
        if (customerId.HasValue) rows = rows.Where(x => x.CustomerId == customerId);
        if (from.HasValue) rows = rows.Where(x => x.OccasionDate >= from.Value.ToUniversalTime().Date);
        if (to.HasValue) rows = rows.Where(x => x.OccasionDate <= to.Value.ToUniversalTime().Date);
        if (!string.IsNullOrWhiteSpace(occasion)) rows = rows.Where(x => x.Occasion.ToLower().Contains(occasion.Trim().ToLower()));
        if (!string.IsNullOrWhiteSpace(query)) { var q = query.Trim().ToLower(); rows = rows.Where(x => x.RecipientName.ToLower().Contains(q) || x.Relationship.ToLower().Contains(q) || x.Occasion.ToLower().Contains(q) || x.RecipientPhone.Contains(q)); }
        return Ok(await WithCustomer(rows).OrderBy(x => x.Contact.OccasionDate).ThenBy(x => x.Contact.RecipientName).ToListAsync());
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var row = await WithCustomer(Db.OccasionContacts.Where(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null)).FirstOrDefaultAsync();
        return row == null ? NotFound() : Ok(row);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SaveOccasionContactRequest request)
    {
        if (!await Db.Customers.AnyAsync(x => x.CompanyId == CompanyId && x.Id == request.CustomerId))
            return BadRequest(new { message = "Customer was not found." });
        var row = new OccasionContact(CompanyId, request.CustomerId);
        try { Apply(row, request); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        Db.OccasionContacts.Add(row); await Db.SaveChangesAsync(); return CreatedAtAction(nameof(Get), new { id = row.Id }, await GetResponse(row.Id));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveOccasionContactRequest request)
    {
        var row = await Db.OccasionContacts.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound();
        if (row.CustomerId != request.CustomerId) return BadRequest(new { message = "Customer cannot be changed." });
        try { Apply(row, request); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await Db.SaveChangesAsync(); return Ok(await GetResponse(row.Id));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var row = await Db.OccasionContacts.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound(); row.Delete(); await Db.SaveChangesAsync(); return NoContent();
    }

    private static void Apply(OccasionContact row, SaveOccasionContactRequest r) => row.Update(r.RecipientName, r.Relationship,
        r.Occasion, r.OccasionDate, r.RecipientPhone, r.Company, r.Notes, r.ReminderEnabled, r.Source);
    private IQueryable<OccasionContactResponse> WithCustomer(IQueryable<OccasionContact> contacts) =>
        from contact in contacts
        join customer in Db.Customers on contact.CustomerId equals customer.Id
        select new OccasionContactResponse(contact, customer.Name, customer.Phone);
    private Task<OccasionContactResponse?> GetResponse(Guid id) => WithCustomer(Db.OccasionContacts.Where(x => x.Id == id)).FirstOrDefaultAsync();
}

public record OccasionContactResponse(OccasionContact Contact, string CustomerName, string? CustomerPhone);

[ApiController, Route("api/occasion-follow-ups"), Authorize(Policy = "CompanyOnly")]
public class OccasionFollowUpsController : MobileParityControllerBase
{
    public OccasionFollowUpsController(SumpoojDbContext db, ITenantContext tenant) : base(db, tenant) { }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] DateTime from, [FromQuery] DateTime to) => Ok(await Db.OccasionFollowUpActions
        .Where(x => x.CompanyId == CompanyId && x.OccurrenceDate >= from.ToUniversalTime().Date && x.OccurrenceDate <= to.ToUniversalTime().Date)
        .OrderBy(x => x.OccurrenceDate).ToListAsync());

    [HttpPut("{sourceType}/{sourceId:guid}/{occurrenceDate:datetime}/done")]
    public Task<IActionResult> Done(string sourceType, Guid sourceId, DateTime occurrenceDate) => Upsert(sourceType, sourceId, occurrenceDate, x => x.Complete());
    [HttpPut("{sourceType}/{sourceId:guid}/{occurrenceDate:datetime}/snooze")]
    public Task<IActionResult> Snooze(string sourceType, Guid sourceId, DateTime occurrenceDate, [FromBody] SnoozeOccasionRequest request) =>
        Upsert(sourceType, sourceId, occurrenceDate, x => x.Snooze(request.SnoozedTo));
    [HttpDelete("{sourceType}/{sourceId:guid}/{occurrenceDate:datetime}")]
    public Task<IActionResult> Delete(string sourceType, Guid sourceId, DateTime occurrenceDate) => Upsert(sourceType, sourceId, occurrenceDate, x => x.Delete());

    private async Task<IActionResult> Upsert(string sourceType, Guid sourceId, DateTime occurrenceDate, Action<OccasionFollowUpAction> action)
    {
        var day = occurrenceDate.ToUniversalTime().Date;
        var row = await Db.OccasionFollowUpActions.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.SourceType == sourceType && x.SourceId == sourceId && x.OccurrenceDate == day);
        if (row == null) { row = new OccasionFollowUpAction(CompanyId, sourceType, sourceId, day); Db.OccasionFollowUpActions.Add(row); }
        action(row); await Db.SaveChangesAsync(); return Ok(row);
    }
}

[ApiController, Route("api/scheduler-records"), Authorize(Policy = "CompanyOnly")]
public class SchedulerRecordsController : MobileParityControllerBase
{
    private static readonly HashSet<string> Statuses = ["pending", "inProgress", "completed", "cancelled", "deferred"];
    public SchedulerRecordsController(SumpoojDbContext db, ITenantContext tenant) : base(db, tenant) { }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] string? status,
        [FromQuery] string? producer, [FromQuery] string? query)
    {
        var rows = Db.SchedulerRecords.Where(x => x.CompanyId == CompanyId && x.DeletedAtUtc == null);
        if (from.HasValue) rows = rows.Where(x => x.ScheduledAt >= from.Value.ToUniversalTime());
        if (to.HasValue) rows = rows.Where(x => x.ScheduledAt <= to.Value.ToUniversalTime());
        if (!string.IsNullOrWhiteSpace(status)) rows = rows.Where(x => x.Status == status);
        if (!string.IsNullOrWhiteSpace(producer)) rows = rows.Where(x => x.Producer == producer);
        if (!string.IsNullOrWhiteSpace(query)) { var q = query.Trim().ToLower(); rows = rows.Where(x => x.Title.ToLower().Contains(q) || x.Notes.ToLower().Contains(q)); }
        return Ok(await rows.OrderBy(x => x.ScheduledAt).ToListAsync());
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var row = await Db.SchedulerRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        return row == null ? NotFound() : Ok(row);
    }

    [HttpPost]
    public async Task<IActionResult> Publish([FromBody] SaveSchedulerRecordRequest request)
    {
        var linkError = await ValidateLinks(request); if (linkError != null) return linkError;
        var row = await Db.SchedulerRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Producer == request.Producer && x.SourceRef == request.SourceRef);
        if (row == null) { row = new SchedulerRecord(CompanyId, request.Producer, request.SourceRef); Db.SchedulerRecords.Add(row); }
        try { Apply(row, request); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await Db.SaveChangesAsync(); return Ok(row);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveSchedulerRecordRequest request)
    {
        var row = await Db.SchedulerRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound();
        if (row.Producer != request.Producer || row.SourceRef != request.SourceRef) return BadRequest(new { message = "Producer and sourceRef cannot be changed." });
        var linkError = await ValidateLinks(request); if (linkError != null) return linkError;
        try { Apply(row, request); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
        await Db.SaveChangesAsync(); return Ok(row);
    }

    [HttpPut("{id:guid}/status")]
    public async Task<IActionResult> SetStatus(Guid id, [FromBody] SetSchedulerStatusRequest request)
    {
        if (!Statuses.Contains(request.Status)) return BadRequest(new { message = "Invalid scheduler status." });
        var row = await Db.SchedulerRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound(); row.SetStatus(request.Status); await Db.SaveChangesAsync(); return Ok(row);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var row = await Db.SchedulerRecords.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound(); row.Delete(); await Db.SaveChangesAsync(); return NoContent();
    }

    private async Task<IActionResult?> ValidateLinks(SaveSchedulerRecordRequest r)
    {
        if (r.LinkedCustomerId.HasValue && !await Db.Customers.AnyAsync(x => x.CompanyId == CompanyId && x.Id == r.LinkedCustomerId)) return BadRequest(new { message = "Customer was not found." });
        if (r.LinkedOrderId.HasValue && !await Db.Orders.AnyAsync(x => x.CompanyId == CompanyId && x.Id == r.LinkedOrderId)) return BadRequest(new { message = "Order was not found." });
        if (r.AssignedStaffId.HasValue && !await Db.Staff.AnyAsync(x => x.CompanyId == CompanyId && x.Id == r.AssignedStaffId)) return BadRequest(new { message = "Staff member was not found." });
        return null;
    }
    private static void Apply(SchedulerRecord row, SaveSchedulerRecordRequest r) => row.Update(r.Title, r.Type, r.Category,
        r.Priority, r.ScheduledAt, r.NextReminderAt, r.DeadlineAt, r.Notes, r.LinkedCustomerId, r.LinkedOrderId,
        r.AssignedStaffId, r.RequiresConfirmation, r.RequiresAlarm);
}

[ApiController, Route("api/designs"), Authorize(Policy = "CompanyOnly")]
public class CloudDesignsController : MobileParityControllerBase
{
    public CloudDesignsController(SumpoojDbContext db, ITenantContext tenant) : base(db, tenant) { }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? query, [FromQuery] string? flower, [FromQuery] string? occasion,
        [FromQuery] string? color, [FromQuery] string? status, [FromQuery] bool? favorite, [FromQuery] int? minPricePaise,
        [FromQuery] int? maxPricePaise)
    {
        var rows = Db.CloudDesigns.Where(x => x.CompanyId == CompanyId && x.DeletedAtUtc == null);
        if (!string.IsNullOrWhiteSpace(query)) { var q = query.Trim().ToLower(); rows = rows.Where(x => x.BouquetId.ToLower().Contains(q) || x.Description.ToLower().Contains(q) || x.Flowers.ToLower().Contains(q) || x.Occasion.ToLower().Contains(q) || x.Color.ToLower().Contains(q) || x.Collection.ToLower().Contains(q) || x.Notes.ToLower().Contains(q)); }
        if (!string.IsNullOrWhiteSpace(flower)) rows = rows.Where(x => x.Flowers.ToLower().Contains(flower.Trim().ToLower()));
        if (!string.IsNullOrWhiteSpace(occasion)) rows = rows.Where(x => x.Occasion.ToLower().Contains(occasion.Trim().ToLower()));
        if (!string.IsNullOrWhiteSpace(color)) rows = rows.Where(x => x.Color.ToLower().Contains(color.Trim().ToLower()));
        if (!string.IsNullOrWhiteSpace(status)) rows = rows.Where(x => x.Status == status);
        if (favorite.HasValue) rows = rows.Where(x => x.IsFavorite == favorite.Value);
        if (minPricePaise.HasValue) rows = rows.Where(x => x.SellingPricePaise >= minPricePaise);
        if (maxPricePaise.HasValue) rows = rows.Where(x => x.SellingPricePaise <= maxPricePaise);
        return Ok(await rows.OrderByDescending(x => x.IsFavorite).ThenByDescending(x => x.UpdatedAtUtc).ToListAsync());
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var row = await Db.CloudDesigns.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        return row == null ? NotFound() : Ok(row);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SaveCloudDesignRequest request)
    {
        var sequence = await Db.CloudDesigns.CountAsync(x => x.CompanyId == CompanyId) + 1;
        var row = new CloudDesign(CompanyId, $"B-{sequence:D4}"); Apply(row, request);
        Db.CloudDesigns.Add(row); await Db.SaveChangesAsync(); return CreatedAtAction(nameof(Get), new { id = row.Id }, row);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveCloudDesignRequest request)
    {
        var row = await Db.CloudDesigns.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound(); Apply(row, request); await Db.SaveChangesAsync(); return Ok(row);
    }

    [HttpPut("{id:guid}/favorite")]
    public async Task<IActionResult> SetFavorite(Guid id, [FromBody] bool favorite)
    {
        var row = await Db.CloudDesigns.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound(); row.Update(row.Description, row.ImageReference, row.SellingPricePaise, row.Flowers,
            row.Occasion, row.Color, row.Collection, row.Notes, favorite); await Db.SaveChangesAsync(); return Ok(row);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var row = await Db.CloudDesigns.FirstOrDefaultAsync(x => x.CompanyId == CompanyId && x.Id == id && x.DeletedAtUtc == null);
        if (row == null) return NotFound(); row.Delete(); await Db.SaveChangesAsync(); return NoContent();
    }

    private static void Apply(CloudDesign row, SaveCloudDesignRequest r) => row.Update(r.Description, r.ImageReference,
        r.SellingPricePaise, r.Flowers, r.Occasion, r.Color, r.Collection, r.Notes, r.IsFavorite);
}