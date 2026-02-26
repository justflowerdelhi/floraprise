using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Barcodes;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Controllers;

[ApiController]
[Route("api/barcodes")]
[Authorize(Policy = PolicyNames.CompanyOnly)]
public class BarcodesController : ControllerBase
{
    private readonly BarcodeService _service;
    private readonly ITenantContext _tenant;

    public BarcodesController(BarcodeService service, ITenantContext tenant)
    {
        _service = service;
        _tenant = tenant;
    }

    private Guid CompanyId =>
        _tenant.CompanyId ?? throw new UnauthorizedAccessException("Company context required");

    /// <summary>
    /// POST /api/barcodes/generate
    /// </summary>
    [HttpPost("generate")]
    public async Task<ActionResult<GenerateBarcodeResponse>> Generate([FromBody] GenerateBarcodeRequest request)
        => Ok(await _service.GenerateAsync(request));

    /// <summary>
    /// POST /api/barcodes/validate
    /// </summary>
    [HttpPost("validate")]
    public async Task<ActionResult<ValidateBarcodeResponse>> Validate([FromBody] ValidateBarcodeRequest request)
        => Ok(await _service.ValidateAsync(CompanyId, request));

    /// <summary>
    /// POST /api/barcodes/search
    /// </summary>
    [HttpPost("search")]
    public async Task<ActionResult<SearchBarcodeResponse>> Search([FromBody] SearchBarcodeRequest request)
        => Ok(await _service.SearchAsync(CompanyId, request));
}
