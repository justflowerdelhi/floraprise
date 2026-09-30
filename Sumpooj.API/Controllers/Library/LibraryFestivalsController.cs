using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/festivals")]
[Authorize]
public class LibraryFestivalsController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryFestivalsController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetFestivals([FromQuery] LibraryFestivalQueryRequest request)
    {
        var result = await _libraryService.GetFestivalsAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetFestival(Guid id)
    {
        var festival = await _libraryService.GetFestivalByIdAsync(id);
        return festival == null ? NotFound(new { message = $"Library festival '{id}' not found." }) : Ok(festival);
    }
}
