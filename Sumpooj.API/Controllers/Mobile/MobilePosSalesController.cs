using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Sumpooj.API.Services.Mobile;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Mobile;

namespace Sumpooj.API.Controllers.Mobile;

[Route("api/v1/mobile/pos-sales")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme, Policy = PolicyNames.CompanyOnly)]
public sealed class MobilePosSalesController : MobileApiControllerBase
{
    private readonly IPosSaleSyncService _service;

    public MobilePosSalesController(IPosSaleSyncService service, ITenantContext tenantContext)
        : base(tenantContext)
    {
        _service = service;
    }

    [HttpPost("sync", Name = "MobilePosSales_Sync")]
    [ProducesResponseType(typeof(PosSaleSyncResponse), StatusCodes.Status200OK)]
    public async Task<IActionResult> Sync([FromBody] JsonElement payload, CancellationToken cancellationToken)
    {
        try
        {
            var request = JsonSerializer.Deserialize<PosSaleSyncRequest>(payload.GetRawText(), new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            }) ?? throw new ArgumentException("Request body is required.");

            var response = await _service.SyncAsync(
                GetCompanyId(),
                GetMobileUserId(),
                InventoryUserIdentityResolver.Resolve(User),
                GetDeviceId(),
                request,
                ComputePayloadHash(payload.GetRawText()),
                cancellationToken);
            return Ok(response);
        }
        catch (DbUpdateException ex)
        {
            return Problem(
                title: "Server Error",
                detail: ex.InnerException is null ? ex.Message : $"{ex.Message} Inner: {ex.InnerException.Message}",
                statusCode: StatusCodes.Status500InternalServerError,
                extensions: new Dictionary<string, object?>());
        }
        catch (Exception ex)
        {
            return ProblemFromException(ex);
        }
    }

    private static string ComputePayloadHash(string json)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(json));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}