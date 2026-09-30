using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/recipes")]
[Authorize]
public class LibraryRecipesController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryRecipesController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetRecipes([FromQuery] LibraryRecipeQueryRequest request)
    {
        var result = await _libraryService.GetRecipesAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetRecipe(Guid id)
    {
        var recipe = await _libraryService.GetRecipeByIdAsync(id);
        return recipe == null ? NotFound(new { message = $"Library recipe '{id}' not found." }) : Ok(recipe);
    }

    [HttpPost("{id:guid}/import")]
    [Authorize(Policy = PolicyNames.CompanyOnly)]
    public async Task<IActionResult> ImportRecipe(Guid id)
    {
        try
        {
            var result = await _libraryService.ImportRecipeAsync(id);
            if (result.AlreadyImported)
            {
                return Ok(result);
            }

            return CreatedAtAction(nameof(GetRecipe), new { id = result.RecipeId }, result);
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
