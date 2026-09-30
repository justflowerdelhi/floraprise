using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Authorization;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/admin/library")]
[Authorize(Policy = PolicyNames.PlatformOnly)]
public class LibraryAdminController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryAdminController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    #region Categories

    [HttpPost("categories")]
    public async Task<IActionResult> CreateCategory([FromBody] CreateOrUpdateLibraryCategoryRequest request)
    {
        try
        {
            var result = await _libraryService.AdminCreateCategoryAsync(request);
            return CreatedAtAction("GetCategory", "LibraryCategories", new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("categories/{id:guid}")]
    public async Task<IActionResult> UpdateCategory(Guid id, [FromBody] CreateOrUpdateLibraryCategoryRequest request)
    {
        try
        {
            var result = await _libraryService.AdminUpdateCategoryAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("categories/{id:guid}/status")]
    public async Task<IActionResult> ToggleCategoryStatus(Guid id, [FromBody] ToggleLibraryStatusRequest request)
    {
        try
        {
            await _libraryService.AdminToggleCategoryStatusAsync(id, request.IsActive);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("categories/{id:guid}")]
    public async Task<IActionResult> DeleteCategory(Guid id)
    {
        try
        {
            await _libraryService.AdminDeleteCategoryAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    #endregion

    #region Products

    [HttpPost("products")]
    public async Task<IActionResult> CreateProduct([FromBody] CreateOrUpdateLibraryProductRequest request)
    {
        try
        {
            var result = await _libraryService.AdminCreateProductAsync(request);
            return CreatedAtAction("GetProduct", "LibraryProducts", new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("products/{id:guid}")]
    public async Task<IActionResult> UpdateProduct(Guid id, [FromBody] CreateOrUpdateLibraryProductRequest request)
    {
        try
        {
            var result = await _libraryService.AdminUpdateProductAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("products/{id:guid}/status")]
    public async Task<IActionResult> ToggleProductStatus(Guid id, [FromBody] ToggleLibraryStatusRequest request)
    {
        try
        {
            await _libraryService.AdminToggleProductStatusAsync(id, request.IsActive);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("products/{id:guid}")]
    public async Task<IActionResult> DeleteProduct(Guid id)
    {
        try
        {
            await _libraryService.AdminDeleteProductAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    #endregion

    #region Recipes

    [HttpPost("recipes")]
    public async Task<IActionResult> CreateRecipe([FromBody] CreateOrUpdateLibraryRecipeRequest request)
    {
        try
        {
            var result = await _libraryService.AdminCreateRecipeAsync(request);
            return CreatedAtAction("GetRecipe", "LibraryRecipes", new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("recipes/{id:guid}")]
    public async Task<IActionResult> UpdateRecipe(Guid id, [FromBody] CreateOrUpdateLibraryRecipeRequest request)
    {
        try
        {
            var result = await _libraryService.AdminUpdateRecipeAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("recipes/{id:guid}/status")]
    public async Task<IActionResult> ToggleRecipeStatus(Guid id, [FromBody] ToggleLibraryStatusRequest request)
    {
        try
        {
            await _libraryService.AdminToggleRecipeStatusAsync(id, request.IsActive);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("recipes/{id:guid}")]
    public async Task<IActionResult> DeleteRecipe(Guid id)
    {
        try
        {
            await _libraryService.AdminDeleteRecipeAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    #endregion

    #region Designs

    [HttpPost("designs")]
    public async Task<IActionResult> CreateDesign([FromBody] CreateOrUpdateLibraryDesignRequest request)
    {
        try
        {
            var result = await _libraryService.AdminCreateDesignAsync(request);
            return CreatedAtAction("GetDesign", "LibraryDesigns", new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("designs/{id:guid}")]
    public async Task<IActionResult> UpdateDesign(Guid id, [FromBody] CreateOrUpdateLibraryDesignRequest request)
    {
        try
        {
            var result = await _libraryService.AdminUpdateDesignAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("designs/{id:guid}/status")]
    public async Task<IActionResult> ToggleDesignStatus(Guid id, [FromBody] ToggleLibraryStatusRequest request)
    {
        try
        {
            await _libraryService.AdminToggleDesignStatusAsync(id, request.IsActive);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("designs/{id:guid}")]
    public async Task<IActionResult> DeleteDesign(Guid id)
    {
        try
        {
            await _libraryService.AdminDeleteDesignAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    #endregion

    #region Cards

    [HttpPost("cards")]
    public async Task<IActionResult> CreateCard([FromBody] CreateOrUpdateLibraryCardRequest request)
    {
        try
        {
            var result = await _libraryService.AdminCreateCardAsync(request);
            return CreatedAtAction("GetCard", "LibraryCards", new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("cards/{id:guid}")]
    public async Task<IActionResult> UpdateCard(Guid id, [FromBody] CreateOrUpdateLibraryCardRequest request)
    {
        try
        {
            var result = await _libraryService.AdminUpdateCardAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("cards/{id:guid}/status")]
    public async Task<IActionResult> ToggleCardStatus(Guid id, [FromBody] ToggleLibraryStatusRequest request)
    {
        try
        {
            await _libraryService.AdminToggleCardStatusAsync(id, request.IsActive);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("cards/{id:guid}")]
    public async Task<IActionResult> DeleteCard(Guid id)
    {
        try
        {
            await _libraryService.AdminDeleteCardAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    #endregion

    #region Tutorials

    [HttpPost("tutorials")]
    public async Task<IActionResult> CreateTutorial([FromBody] CreateOrUpdateLibraryTutorialRequest request)
    {
        try
        {
            var result = await _libraryService.AdminCreateTutorialAsync(request);
            return CreatedAtAction("GetTutorial", "LibraryTutorials", new { id = result.Id }, result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("tutorials/{id:guid}")]
    public async Task<IActionResult> UpdateTutorial(Guid id, [FromBody] CreateOrUpdateLibraryTutorialRequest request)
    {
        try
        {
            var result = await _libraryService.AdminUpdateTutorialAsync(id, request);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("tutorials/{id:guid}/status")]
    public async Task<IActionResult> ToggleTutorialStatus(Guid id, [FromBody] ToggleLibraryStatusRequest request)
    {
        try
        {
            await _libraryService.AdminToggleTutorialStatusAsync(id, request.IsActive);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("tutorials/{id:guid}")]
    public async Task<IActionResult> DeleteTutorial(Guid id)
    {
        try
        {
            await _libraryService.AdminDeleteTutorialAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    #endregion
}
