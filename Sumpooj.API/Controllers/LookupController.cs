using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Domain.Entities;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/lookup")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class LookupController : ControllerBase
{
    [HttpGet("product-types")]
    public IActionResult GetProductTypes()
    {
        var types = Enum.GetValues<ProductType>()
            .Select(t => new { value = t.ToString().ToLower(), label = FormatEnumName(t.ToString()) })
            .ToList();
        return Ok(types);
    }

    [HttpGet("product-categories")]
    public IActionResult GetProductCategories()
    {
        var categories = Enum.GetValues<ProductCategory>()
            .Select(c => new { value = c.ToString().ToLower(), label = FormatEnumName(c.ToString()) })
            .ToList();
        return Ok(categories);
    }

    [HttpGet("units-of-measure")]
    public IActionResult GetUnitsOfMeasure()
    {
        var units = Enum.GetValues<UnitOfMeasure>()
            .Select(u => new { value = u.ToString().ToLower(), label = FormatEnumName(u.ToString()) })
            .ToList();
        return Ok(units);
    }

    [HttpGet("tax-categories")]
    public IActionResult GetTaxCategories()
    {
        var categories = Enum.GetValues<TaxCategory>()
            .Select(t => new { value = t.ToString().ToLower(), label = FormatEnumName(t.ToString()) })
            .ToList();
        return Ok(categories);
    }

    [HttpGet("flower-grades")]
    public IActionResult GetFlowerGrades()
    {
        var grades = Enum.GetValues<FlowerGrade>()
            .Select(g => new { value = g.ToString().ToLower(), label = FormatEnumName(g.ToString()) })
            .ToList();
        return Ok(grades);
    }

    [HttpGet("seasonal-availability")]
    public IActionResult GetSeasonalAvailability()
    {
        var seasons = Enum.GetValues<SeasonalAvailability>()
            .Select(s => new { value = s.ToString().ToLower(), label = FormatEnumName(s.ToString()) })
            .ToList();
        return Ok(seasons);
    }

    [HttpGet("adjustment-types")]
    public IActionResult GetAdjustmentTypes()
    {
        var types = Enum.GetValues<AdjustmentType>()
            .Select(t => new { value = t.ToString().ToLower(), label = FormatEnumName(t.ToString()) })
            .ToList();
        return Ok(types);
    }

    [HttpGet("location-types")]
    public IActionResult GetLocationTypes()
    {
        var types = Enum.GetValues<LocationType>()
            .Select(t => new { value = t.ToString().ToLower(), label = FormatEnumName(t.ToString()) })
            .ToList();
        return Ok(types);
    }

    [HttpGet("purchase-order-statuses")]
    public IActionResult GetPurchaseOrderStatuses()
    {
        var statuses = Enum.GetValues<PurchaseOrderStatus>()
            .Select(s => new { value = s.ToString().ToLower(), label = FormatEnumName(s.ToString()) })
            .ToList();
        return Ok(statuses);
    }

    [HttpGet("order-statuses")]
    public IActionResult GetOrderStatuses()
    {
        var statuses = Enum.GetValues<OrderStatus>()
            .Select(s => new { value = s.ToString().ToLower(), label = FormatEnumName(s.ToString()) })
            .ToList();
        return Ok(statuses);
    }

    private static string FormatEnumName(string name)
    {
        // Convert PascalCase to Title Case with spaces
        return string.Concat(name.Select((x, i) => i > 0 && char.IsUpper(x) ? " " + x : x.ToString()));
    }
}
