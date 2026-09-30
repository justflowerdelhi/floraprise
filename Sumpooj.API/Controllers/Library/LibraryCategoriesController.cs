using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/categories")]
[Authorize]
public class LibraryCategoriesController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryCategoriesController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetCategories([FromQuery] LibraryCategoryQueryRequest request)
    {
        var result = await _libraryService.GetCategoriesAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetCategory(Guid id)
    {
        var category = await _libraryService.GetCategoryByIdAsync(id);
        return category == null ? NotFound(new { message = $"Library category '{id}' not found." }) : Ok(category);
    }

    [HttpGet("tree")]
    public async Task<IActionResult> GetCategoryTree()
    {
        var tree = await _libraryService.GetCategoryTreeAsync();
        return Ok(tree);
    }
}
