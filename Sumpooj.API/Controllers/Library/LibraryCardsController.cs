using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/cards")]
[Authorize]
public class LibraryCardsController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryCardsController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetCards([FromQuery] LibraryCardQueryRequest request)
    {
        var result = await _libraryService.GetCardsAsync(request);
        return Ok(result);
    }

    [HttpGet("occasions")]
    public async Task<IActionResult> GetOccasions([FromQuery] string? language)
    {
        var result = await _libraryService.GetCardOccasionsSummaryAsync(language);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetCard(Guid id)
    {
        var card = await _libraryService.GetCardByIdAsync(id);
        return card == null ? NotFound(new { message = $"Library card template '{id}' not found." }) : Ok(card);
    }
}
