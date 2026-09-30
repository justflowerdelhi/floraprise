using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Sumpooj.Application.Library;

namespace Sumpooj.API.Controllers.Library;

[ApiController]
[Route("api/v1/library/manifest")]
[Authorize]
public class LibraryManifestController : ControllerBase
{
    private readonly ILibraryService _libraryService;

    public LibraryManifestController(ILibraryService libraryService)
    {
        _libraryService = libraryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetManifest()
    {
        var manifest = await _libraryService.GetManifestAsync();
        return Ok(manifest);
    }
}
