using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/tutorials")]
[Authorize]
public class LibraryTutorialsController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryTutorialsController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetTutorials([FromQuery] LibraryTutorialQueryRequest request)
    {
        var result = await _libraryService.GetTutorialsAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetTutorial(Guid id)
    {
        var tutorial = await _libraryService.GetTutorialByIdAsync(id);
        return tutorial == null ? NotFound(new { message = $"Library tutorial '{id}' not found." }) : Ok(tutorial);
    }

    [HttpGet("slug/{slug}")]
    public async Task<IActionResult> GetTutorialBySlug(string slug)
    {
        var tutorial = await _libraryService.GetTutorialBySlugAsync(slug);
        return tutorial == null ? NotFound(new { message = $"Library tutorial with slug '{slug}' not found." }) : Ok(tutorial);
    }
}
