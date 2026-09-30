using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/products")]
[Authorize]
public class LibraryProductsController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryProductsController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts([FromQuery] LibraryProductQueryRequest request)
    {
        var result = await _libraryService.GetProductsAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetProduct(Guid id)
    {
        var product = await _libraryService.GetProductByIdAsync(id);
        return product == null ? NotFound(new { message = $"Library product '{id}' not found." }) : Ok(product);
    }

    [HttpPost("{id:guid}/import")]
    [Authorize(Policy = PolicyNames.CompanyOnly)]
    public async Task<IActionResult> ImportProduct(Guid id, [FromBody] ImportLibraryProductRequest? request = null)
    {
        try
        {
            var result = await _libraryService.ImportProductAsync(id, request);
            if (result.AlreadyImported)
            {
                return Ok(result);
            }

            return CreatedAtAction(nameof(GetProduct), new { id = result.ProductId }, result);
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
