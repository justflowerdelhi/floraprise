using Sumpooj.Application.Common;

namespace Sumpooj.Application.Library;

public interface ILibraryService
{
    // Categories
    Task<PagedResult<LibraryCategoryDto>> GetCategoriesAsync(LibraryCategoryQueryRequest request);
    Task<LibraryCategoryDto?> GetCategoryByIdAsync(Guid id);
    Task<List<LibraryCategoryTreeDto>> GetCategoryTreeAsync();

    // Products
    Task<PagedResult<LibraryProductListItemDto>> GetProductsAsync(LibraryProductQueryRequest request);
    Task<LibraryProductDetailDto?> GetProductByIdAsync(Guid id);
    Task<ImportLibraryProductResultDto> ImportProductAsync(Guid libraryProductId, ImportLibraryProductRequest? request = null);

    // Recipes
    Task<PagedResult<LibraryRecipeListItemDto>> GetRecipesAsync(LibraryRecipeQueryRequest request);
    Task<LibraryRecipeDetailDto?> GetRecipeByIdAsync(Guid id);
    Task<ImportLibraryRecipeResultDto> ImportRecipeAsync(Guid libraryRecipeId);

    // Designs
    Task<PagedResult<LibraryDesignListItemDto>> GetDesignsAsync(LibraryDesignQueryRequest request);
    Task<LibraryDesignDetailDto?> GetDesignByIdAsync(Guid id);
    Task<ImportLibraryDesignResultDto> ImportDesignAsync(Guid libraryDesignId);

    // Greeting Cards
    Task<PagedResult<LibraryCardListItemDto>> GetCardsAsync(LibraryCardQueryRequest request);
    Task<LibraryCardDetailDto?> GetCardByIdAsync(Guid id);
    Task<List<LibraryCardOccasionSummaryDto>> GetCardOccasionsSummaryAsync(string? language = null);

    // Tutorials
    Task<PagedResult<LibraryTutorialListItemDto>> GetTutorialsAsync(LibraryTutorialQueryRequest request);
    Task<LibraryTutorialDetailDto?> GetTutorialByIdAsync(Guid id);
    Task<LibraryTutorialDetailDto?> GetTutorialBySlugAsync(string slug);

    // Festivals
    Task<PagedResult<LibraryFestivalListItemDto>> GetFestivalsAsync(LibraryFestivalQueryRequest request);
    Task<LibraryFestivalDetailDto?> GetFestivalByIdAsync(Guid id);

    // Wedding Dates
    Task<PagedResult<LibraryWeddingDateListItemDto>> GetWeddingDatesAsync(LibraryWeddingDateQueryRequest request);
    Task<LibraryWeddingDateDetailDto?> GetWeddingDateByIdAsync(Guid id);

    // Manifest
    Task<LibraryManifestDto> GetManifestAsync();

    // Admin Management
    Task<LibraryCategoryDto> AdminCreateCategoryAsync(CreateOrUpdateLibraryCategoryRequest request);
    Task<LibraryCategoryDto> AdminUpdateCategoryAsync(Guid id, CreateOrUpdateLibraryCategoryRequest request);
    Task AdminToggleCategoryStatusAsync(Guid id, bool isActive);
    Task AdminDeleteCategoryAsync(Guid id);

    Task<LibraryProductDetailDto> AdminCreateProductAsync(CreateOrUpdateLibraryProductRequest request);
    Task<LibraryProductDetailDto> AdminUpdateProductAsync(Guid id, CreateOrUpdateLibraryProductRequest request);
    Task AdminToggleProductStatusAsync(Guid id, bool isActive);
    Task AdminDeleteProductAsync(Guid id);

    Task<LibraryRecipeDetailDto> AdminCreateRecipeAsync(CreateOrUpdateLibraryRecipeRequest request);
    Task<LibraryRecipeDetailDto> AdminUpdateRecipeAsync(Guid id, CreateOrUpdateLibraryRecipeRequest request);
    Task AdminToggleRecipeStatusAsync(Guid id, bool isActive);
    Task AdminDeleteRecipeAsync(Guid id);

    Task<LibraryDesignDetailDto> AdminCreateDesignAsync(CreateOrUpdateLibraryDesignRequest request);
    Task<LibraryDesignDetailDto> AdminUpdateDesignAsync(Guid id, CreateOrUpdateLibraryDesignRequest request);
    Task AdminToggleDesignStatusAsync(Guid id, bool isActive);
    Task AdminDeleteDesignAsync(Guid id);

    Task<LibraryCardDetailDto> AdminCreateCardAsync(CreateOrUpdateLibraryCardRequest request);
    Task<LibraryCardDetailDto> AdminUpdateCardAsync(Guid id, CreateOrUpdateLibraryCardRequest request);
    Task AdminToggleCardStatusAsync(Guid id, bool isActive);
    Task AdminDeleteCardAsync(Guid id);

    Task<LibraryTutorialDetailDto> AdminCreateTutorialAsync(CreateOrUpdateLibraryTutorialRequest request);
    Task<LibraryTutorialDetailDto> AdminUpdateTutorialAsync(Guid id, CreateOrUpdateLibraryTutorialRequest request);
    Task AdminToggleTutorialStatusAsync(Guid id, bool isActive);
    Task AdminDeleteTutorialAsync(Guid id);
}
