using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/designs")]
[Authorize]
public class LibraryDesignsController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryDesignsController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetDesigns([FromQuery] LibraryDesignQueryRequest request)
    {
        var result = await _libraryService.GetDesignsAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetDesign(Guid id)
    {
        var design = await _libraryService.GetDesignByIdAsync(id);
        return design == null ? NotFound(new { message = $"Library design '{id}' not found." }) : Ok(design);
    }

    [HttpPost("{id:guid}/import")]
    [Authorize(Policy = PolicyNames.CompanyOnly)]
    public async Task<IActionResult> ImportDesign(Guid id)
    {
        try
        {
            var result = await _libraryService.ImportDesignAsync(id);
            if (result.AlreadyImported)
            {
                return Ok(result);
            }

            return CreatedAtAction(nameof(GetDesign), new { id = result.DesignId }, result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            var msg = ex.InnerException?.Message ?? ex.Message;
            return StatusCode(500, new { message = msg });
        }
    }
}
