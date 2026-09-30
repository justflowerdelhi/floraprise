using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/wedding-dates")]
[Authorize]
public class LibraryWeddingDatesController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryWeddingDatesController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetWeddingDates([FromQuery] LibraryWeddingDateQueryRequest request)
    {
        var result = await _libraryService.GetWeddingDatesAsync(request);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetWeddingDate(Guid id)
    {
        var weddingDate = await _libraryService.GetWeddingDateByIdAsync(id);
        return weddingDate == null ? NotFound(new { message = $"Library wedding date '{id}' not found." }) : Ok(weddingDate);
    }
}
