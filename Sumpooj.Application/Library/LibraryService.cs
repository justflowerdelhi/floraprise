using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Logging;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Production;
using Sumpooj.Application.Products;
using Sumpooj.Application.UseCases;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Library;

public class LibraryService : ILibraryService
{
    private readonly ILibraryCategoryRepository _categoryRepo;
    private readonly ILibraryProductRepository _productRepo;
    private readonly ILibraryRecipeRepository _recipeRepo;
    private readonly ILibraryDesignRepository _designRepo;
    private readonly ILibraryCardRepository _cardRepo;
    private readonly ILibraryTutorialRepository _tutorialRepo;
    private readonly ILibraryFestivalRepository _festivalRepo;
    private readonly ILibraryWeddingDateRepository _weddingDateRepo;
    private readonly IProductRepository _companyProductRepo;
    private readonly IProductCategoryRepository _companyCategoryRepo;
    private readonly IFloralRecipeRepository _companyRecipeRepo;
    private readonly ICloudDesignRepository _companyDesignRepo;
    private readonly IBarcodeRepository _barcodeRepo;
    private readonly BarcodeService _barcodeService;
    private readonly ITenantContext _tenant;
    private readonly ILogger<LibraryService> _logger;

    public LibraryService(
        ILibraryCategoryRepository categoryRepo,
        ILibraryProductRepository productRepo,
        ILibraryRecipeRepository recipeRepo,
        ILibraryDesignRepository designRepo,
        ILibraryCardRepository cardRepo,
        ILibraryTutorialRepository tutorialRepo,
        ILibraryFestivalRepository festivalRepo,
        ILibraryWeddingDateRepository weddingDateRepo,
        IProductRepository companyProductRepo,
        IProductCategoryRepository companyCategoryRepo,
        IFloralRecipeRepository companyRecipeRepo,
        ICloudDesignRepository companyDesignRepo,
        IBarcodeRepository barcodeRepo,
        BarcodeService barcodeService,
        ITenantContext tenant,
        ILogger<LibraryService> logger)
    {
        _categoryRepo = categoryRepo;
        _productRepo = productRepo;
        _recipeRepo = recipeRepo;
        _designRepo = designRepo;
        _cardRepo = cardRepo;
        _tutorialRepo = tutorialRepo;
        _festivalRepo = festivalRepo;
        _weddingDateRepo = weddingDateRepo;
        _companyProductRepo = companyProductRepo;
        _companyCategoryRepo = companyCategoryRepo;
        _companyRecipeRepo = companyRecipeRepo;
        _companyDesignRepo = companyDesignRepo;
        _barcodeRepo = barcodeRepo;
        _barcodeService = barcodeService;
        _tenant = tenant;
        _logger = logger;
    }

    #region Categories

    public async Task<PagedResult<LibraryCategoryDto>> GetCategoriesAsync(LibraryCategoryQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 30 : request.PageSize, 1, 100);

        var (items, total) = await _categoryRepo.SearchAsync(
            request.Search,
            request.IsActive,
            request.ParentCategoryId,
            page,
            pageSize);

        var dtos = new List<LibraryCategoryDto>(items.Count);
        foreach (var c in items)
        {
            var productCount = await _categoryRepo.GetProductCountAsync(c.Id);
            dtos.Add(ToCategoryDto(c, productCount));
        }

        return new PagedResult<LibraryCategoryDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryCategoryDto?> GetCategoryByIdAsync(Guid id)
    {
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null) return null;

        var productCount = await _categoryRepo.GetProductCountAsync(category.Id);
        return ToCategoryDto(category, productCount);
    }

    public async Task<List<LibraryCategoryTreeDto>> GetCategoryTreeAsync()
    {
        var allCategories = await _categoryRepo.GetAllActiveAsync();
        var rootCategories = allCategories.Where(c => c.ParentCategoryId == null).OrderBy(c => c.SortOrder).ThenBy(c => c.Name).ToList();

        var result = new List<LibraryCategoryTreeDto>();
        foreach (var root in rootCategories)
        {
            result.Add(await BuildTreeItemAsync(root, allCategories));
        }

        return result;
    }

    private async Task<LibraryCategoryTreeDto> BuildTreeItemAsync(LibraryCategory current, List<LibraryCategory> allCategories)
    {
        var productCount = await _categoryRepo.GetProductCountAsync(current.Id);
        var dto = new LibraryCategoryTreeDto
        {
            Id = current.Id,
            Name = current.Name,
            Slug = current.Slug,
            Description = current.Description,
            ImageUrl = current.ImageUrl,
            IconKey = current.IconKey,
            SortOrder = current.SortOrder,
            IsActive = current.IsActive,
            ProductCount = productCount
        };

        var directChildren = allCategories
            .Where(c => c.ParentCategoryId == current.Id)
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.Name);

        foreach (var child in directChildren)
        {
            dto.Children.Add(await BuildTreeItemAsync(child, allCategories));
        }

        return dto;
    }

    #endregion

    #region Products

    public async Task<PagedResult<LibraryProductListItemDto>> GetProductsAsync(LibraryProductQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 30 : request.PageSize, 1, 100);

        ProductType? parsedType = null;
        if (!string.IsNullOrWhiteSpace(request.ProductType) &&
            Enum.TryParse<ProductType>(request.ProductType, true, out var pt))
        {
            parsedType = pt;
        }

        var (items, total) = await _productRepo.SearchAsync(
            request.Search,
            request.CategoryId,
            parsedType,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToProductListItemDto).ToList();
        return new PagedResult<LibraryProductListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryProductDetailDto?> GetProductByIdAsync(Guid id)
    {
        var product = await _productRepo.GetByIdAsync(id);
        return product == null ? null : ToProductDetailDto(product);
    }

    public async Task<ImportLibraryProductResultDto> ImportProductAsync(Guid libraryProductId, ImportLibraryProductRequest? request = null)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required for importing products.");

        var companyId = _tenant.CompanyId.Value;

        var libraryProduct = await _productRepo.GetByIdAsync(libraryProductId);
        if (libraryProduct == null || !libraryProduct.IsActive)
        {
            throw new KeyNotFoundException($"Library product '{libraryProductId}' not found or is inactive.");
        }

        // Idempotency: check if company already imported this library product
        var existingProduct = await _companyProductRepo.GetBySourceLibraryProductIdAsync(companyId, libraryProductId);
        if (existingProduct != null)
        {
            var existingBarcodes = await _barcodeRepo.GetByProductIdAsync(existingProduct.Id);
            return new ImportLibraryProductResultDto
            {
                Success = true,
                AlreadyImported = true,
                ProductId = existingProduct.Id,
                Message = "Product has already been imported into your company catalog.",
                Product = ProductService.ToDto(existingProduct, existingBarcodes)
            };
        }

        // Determine company CategoryId
        Guid categoryId;
        if (request?.CustomCategoryId.HasValue == true && request.CustomCategoryId.Value != Guid.Empty)
        {
            var customCategory = await _companyCategoryRepo.GetByIdAsync(request.CustomCategoryId.Value);
            if (customCategory == null)
                throw new InvalidOperationException($"Category '{request.CustomCategoryId.Value}' not found.");
            categoryId = customCategory.Id;
        }
        else
        {
            var companyCategories = await _companyCategoryRepo.GetAllAsync(includeInactive: false);
            var matchingCategory = companyCategories.FirstOrDefault(c =>
                libraryProduct.Category != null &&
                string.Equals(c.Name, libraryProduct.Category.Name, StringComparison.OrdinalIgnoreCase));

            if (matchingCategory != null)
            {
                categoryId = matchingCategory.Id;
            }
            else
            {
                // Create a matching company category if not exists
                var categoryName = libraryProduct.Category?.Name ?? "General Flowers";
                var isPerishable = libraryProduct.ProductType == ProductType.SingleFlower ||
                                   libraryProduct.ProductType == ProductType.Bouquet ||
                                   libraryProduct.ProductType == ProductType.Arrangement;

                var newCategory = new ProductCategoryEntity(
                    companyId: companyId,
                    name: categoryName,
                    isPerishable: isPerishable,
                    trackBatchByDefault: false,
                    defaultUnit: libraryProduct.StandardUnit.ToString());

                await _companyCategoryRepo.AddAsync(newCategory);
                categoryId = newCategory.Id;
            }
        }

        // Determine unique SKU for the company
        var baseSku = !string.IsNullOrWhiteSpace(request?.CustomSku)
            ? request.CustomSku.Trim()
            : (!string.IsNullOrWhiteSpace(libraryProduct.StandardSku)
                ? libraryProduct.StandardSku.Trim()
                : $"LP-{libraryProduct.Slug.ToUpperInvariant()}");

        var finalSku = baseSku;
        var skuSuffix = 1;
        while (await _companyProductRepo.SkuExistsAsync(finalSku))
        {
            finalSku = $"{baseSku}-{skuSuffix}";
            skuSuffix++;
        }

        var retailPrice = request?.CustomRetailPrice ?? 0m;
        var costPrice = request?.CustomCostPrice ?? 0m;

        if (retailPrice < 0 || costPrice < 0)
            throw new ArgumentException("Prices cannot be negative.");

        var product = new Product(
            companyId: companyId,
            name: libraryProduct.Name,
            sku: finalSku,
            productType: libraryProduct.ProductType,
            category: ProductCategory.Other,
            retailPrice: retailPrice,
            costPrice: costPrice,
            description: libraryProduct.Description
        );

        product.SetCategoryId(categoryId);
        product.SetSourceLibraryProductId(libraryProduct.Id);
        product.SetUnitOfMeasure(libraryProduct.StandardUnit);
        product.SetInventorySettings(trackInventory: true, trackBatch: false, reorderLevel: 0);

        const int maxAttempts = 5;
        for (var attempt = 0; attempt < maxAttempts; attempt++)
        {
            var barcodes = new List<Barcode>();
            var internalValue = await _barcodeService.GenerateUniqueInternalValueAsync(companyId);
            barcodes.Add(new Barcode(companyId, product.Id, BarcodeType.Internal, internalValue));

            try
            {
                await _companyProductRepo.AddAsync(product, barcodes);
                _logger.LogInformation(
                    "Imported library product {LibraryProductId} as Product {ProductId} ({Sku}) for company {CompanyId}",
                    libraryProduct.Id, product.Id, product.Sku, companyId);

                var dto = ProductService.ToDto(product, barcodes);
                return new ImportLibraryProductResultDto
                {
                    Success = true,
                    AlreadyImported = false,
                    ProductId = product.Id,
                    Message = "Product successfully imported from library.",
                    Product = dto
                };
            }
            catch (ConcurrencyConflictException) when (attempt < maxAttempts - 1)
            {
                // Retry with new barcode
            }
        }

        throw new InvalidOperationException("Unable to import product: could not allocate a unique internal barcode.");
    }

    #endregion

    #region Recipes

    public async Task<PagedResult<LibraryRecipeListItemDto>> GetRecipesAsync(LibraryRecipeQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 30 : request.PageSize, 1, 100);

        var (items, total) = await _recipeRepo.SearchAsync(
            request.Search,
            request.CategoryId,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToRecipeListItemDto).ToList();
        return new PagedResult<LibraryRecipeListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryRecipeDetailDto?> GetRecipeByIdAsync(Guid id)
    {
        var recipe = await _recipeRepo.GetByIdAsync(id);
        return recipe == null ? null : ToRecipeDetailDto(recipe);
    }

    public async Task<ImportLibraryRecipeResultDto> ImportRecipeAsync(Guid libraryRecipeId)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required for importing recipes.");

        var companyId = _tenant.CompanyId.Value;

        var libraryRecipe = await _recipeRepo.GetByIdAsync(libraryRecipeId);
        if (libraryRecipe == null || !libraryRecipe.IsActive)
        {
            throw new KeyNotFoundException($"Library recipe '{libraryRecipeId}' not found or is inactive.");
        }

        // Idempotency: check if company already imported this recipe
        var existingRecipe = await _companyRecipeRepo.GetBySourceLibraryRecipeIdAsync(companyId, libraryRecipeId);
        if (existingRecipe != null)
        {
            return new ImportLibraryRecipeResultDto
            {
                Success = true,
                AlreadyImported = true,
                RecipeId = existingRecipe.Id,
                Message = "Recipe has already been imported into your company catalog.",
                Recipe = ProductionService.MapRecipe(existingRecipe)
            };
        }

        var recipe = new FloralRecipe(
            companyId: companyId,
            name: libraryRecipe.Name,
            category: libraryRecipe.Category?.Name ?? "General",
            sellingPrice: 0m,
            laborCost: 0m
        );

        recipe.SetSourceLibraryRecipeId(libraryRecipe.Id);

        if (!string.IsNullOrWhiteSpace(libraryRecipe.ImageUrl))
        {
            recipe.Update(
                libraryRecipe.Name,
                libraryRecipe.Category?.Name ?? "General",
                sellingPrice: 0m,
                laborCost: 0m,
                sampleImages: libraryRecipe.ImageUrl);
        }

        // Map recipe components
        foreach (var item in libraryRecipe.Items.OrderBy(i => i.SortOrder))
        {
            Guid componentProductId = Guid.Empty;
            string componentProductName = item.ProductNameSnapshot;

            if (item.LibraryProductId.HasValue)
            {
                var companyProduct = await _companyProductRepo.GetBySourceLibraryProductIdAsync(companyId, item.LibraryProductId.Value);
                if (companyProduct != null)
                {
                    componentProductId = companyProduct.Id;
                    componentProductName = companyProduct.Name;
                }
            }

            var quantity = Math.Max(1, (int)Math.Round(item.Quantity));
            recipe.Components.Add(new RecipeComponent(
                recipeId: recipe.Id,
                productId: componentProductId,
                productName: componentProductName,
                quantityRequired: quantity,
                unitCost: 0m));
        }

        await _companyRecipeRepo.AddAsync(recipe);
        _logger.LogInformation("Imported library recipe {LibraryRecipeId} ('{Name}') as company recipe {RecipeId} for company {CompanyId}",
            libraryRecipe.Id, libraryRecipe.Name, recipe.Id, companyId);

        return new ImportLibraryRecipeResultDto
        {
            Success = true,
            AlreadyImported = false,
            RecipeId = recipe.Id,
            Message = "Recipe successfully imported from library.",
            Recipe = ProductionService.MapRecipe(recipe)
        };
    }

    #endregion

    #region Designs

    public async Task<PagedResult<LibraryDesignListItemDto>> GetDesignsAsync(LibraryDesignQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 30 : request.PageSize, 1, 100);

        var (items, total) = await _designRepo.SearchAsync(
            request.Search,
            request.CategoryId,
            request.Occasion,
            request.Style,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToDesignListItemDto).ToList();
        return new PagedResult<LibraryDesignListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryDesignDetailDto?> GetDesignByIdAsync(Guid id)
    {
        var design = await _designRepo.GetByIdAsync(id);
        return design == null ? null : ToDesignDetailDto(design);
    }

    public async Task<ImportLibraryDesignResultDto> ImportDesignAsync(Guid libraryDesignId)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required for importing designs.");

        var companyId = _tenant.CompanyId.Value;

        var libraryDesign = await _designRepo.GetByIdAsync(libraryDesignId);
        if (libraryDesign == null || !libraryDesign.IsActive)
        {
            throw new KeyNotFoundException($"Library design '{libraryDesignId}' not found or is inactive.");
        }

        // Idempotency: check if company already imported this design
        var existingDesign = await _companyDesignRepo.GetBySourceLibraryDesignIdAsync(companyId, libraryDesignId);
        if (existingDesign != null)
        {
            return new ImportLibraryDesignResultDto
            {
                Success = true,
                AlreadyImported = true,
                DesignId = existingDesign.Id,
                BouquetId = existingDesign.BouquetId,
                Message = "Design has already been imported into your cloud designs."
            };
        }

        var sequence = await _companyDesignRepo.CountByCompanyAsync(companyId) + 1;
        var bouquetId = $"B-{sequence:D4}";

        var cloudDesign = new CloudDesign(companyId, bouquetId);
        cloudDesign.SetSourceLibraryDesignId(libraryDesign.Id);

        var description = libraryDesign.Title;
        if (!string.IsNullOrWhiteSpace(libraryDesign.Description))
        {
            description = $"{libraryDesign.Title} - {libraryDesign.Description}";
        }

        cloudDesign.Update(
            description: description,
            imageReference: libraryDesign.ImageUrl,
            sellingPricePaise: null,
            flowers: libraryDesign.FlowerTypes,
            occasion: libraryDesign.Occasion,
            color: libraryDesign.ColorPalette,
            collection: libraryDesign.Style,
            notes: string.Empty,
            favorite: false);

        await _companyDesignRepo.AddAsync(cloudDesign);
        _logger.LogInformation("Imported library design {LibraryDesignId} ('{Title}') as CloudDesign {CloudDesignId} ({BouquetId}) for company {CompanyId}",
            libraryDesign.Id, libraryDesign.Title, cloudDesign.Id, cloudDesign.BouquetId, companyId);

        return new ImportLibraryDesignResultDto
        {
            Success = true,
            AlreadyImported = false,
            DesignId = cloudDesign.Id,
            BouquetId = cloudDesign.BouquetId,
            Message = "Design successfully imported from library."
        };
    }

    #endregion

    #region Cards

    public async Task<PagedResult<LibraryCardListItemDto>> GetCardsAsync(LibraryCardQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 50 : request.PageSize, 1, 100);

        var (items, total) = await _cardRepo.SearchAsync(
            request.Search,
            request.CategoryId,
            request.Occasion,
            request.Tone,
            request.Language,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToCardListItemDto).ToList();
        return new PagedResult<LibraryCardListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryCardDetailDto?> GetCardByIdAsync(Guid id)
    {
        var card = await _cardRepo.GetByIdAsync(id);
        return card == null ? null : ToCardDetailDto(card);
    }

    public async Task<List<LibraryCardOccasionSummaryDto>> GetCardOccasionsSummaryAsync(string? language = null)
    {
        var results = await _cardRepo.GetOccasionsSummaryAsync(language);
        return results.Select(r => new LibraryCardOccasionSummaryDto
        {
            Occasion = r.Occasion,
            Count = r.Count
        }).ToList();
    }

    #endregion

    #region Tutorials

    public async Task<PagedResult<LibraryTutorialListItemDto>> GetTutorialsAsync(LibraryTutorialQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 30 : request.PageSize, 1, 100);

        var (items, total) = await _tutorialRepo.SearchAsync(
            request.Search,
            request.CategoryId,
            request.DifficultyLevel,
            request.Tag,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToTutorialListItemDto).ToList();
        return new PagedResult<LibraryTutorialListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryTutorialDetailDto?> GetTutorialByIdAsync(Guid id)
    {
        var tutorial = await _tutorialRepo.GetByIdAsync(id);
        return tutorial == null ? null : ToTutorialDetailDto(tutorial);
    }

    public async Task<LibraryTutorialDetailDto?> GetTutorialBySlugAsync(string slug)
    {
        var tutorial = await _tutorialRepo.GetBySlugAsync(slug);
        return tutorial == null ? null : ToTutorialDetailDto(tutorial);
    }

    #endregion

    #region Festivals

    public async Task<PagedResult<LibraryFestivalListItemDto>> GetFestivalsAsync(LibraryFestivalQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 50 : request.PageSize, 1, 100);

        var (items, total) = await _festivalRepo.SearchAsync(
            request.Search,
            request.Month,
            request.From,
            request.To,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToFestivalListItemDto).ToList();
        return new PagedResult<LibraryFestivalListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryFestivalDetailDto?> GetFestivalByIdAsync(Guid id)
    {
        var festival = await _festivalRepo.GetByIdAsync(id);
        return festival == null ? null : ToFestivalDetailDto(festival);
    }

    #endregion

    #region Wedding Dates

    public async Task<PagedResult<LibraryWeddingDateListItemDto>> GetWeddingDatesAsync(LibraryWeddingDateQueryRequest request)
    {
        var page = Math.Max(1, request.Page);
        var pageSize = Math.Clamp(request.PageSize <= 0 ? 50 : request.PageSize, 1, 100);

        var (items, total) = await _weddingDateRepo.SearchAsync(
            request.Search,
            request.Season,
            request.DemandLevel,
            request.From,
            request.To,
            request.IsActive,
            page,
            pageSize);

        var dtos = items.Select(ToWeddingDateListItemDto).ToList();
        return new PagedResult<LibraryWeddingDateListItemDto>(dtos, total, page, pageSize);
    }

    public async Task<LibraryWeddingDateDetailDto?> GetWeddingDateByIdAsync(Guid id)
    {
        var weddingDate = await _weddingDateRepo.GetByIdAsync(id);
        return weddingDate == null ? null : ToWeddingDateDetailDto(weddingDate);
    }

    #endregion

    #region Manifest

    public async Task<LibraryManifestDto> GetManifestAsync()
    {
        var (categories, catTotal) = await _categoryRepo.SearchAsync(null, true, null, 1, 1);
        var (products, prodTotal) = await _productRepo.SearchAsync(null, null, null, true, 1, 1);
        var (recipes, recTotal) = await _recipeRepo.SearchAsync(null, null, true, 1, 1);
        var (designs, desTotal) = await _designRepo.SearchAsync(null, null, null, null, true, 1, 1);
        var (cards, cardTotal) = await _cardRepo.SearchAsync(null, null, null, null, null, true, 1, 1);
        var (tutorials, tutTotal) = await _tutorialRepo.SearchAsync(null, null, null, null, true, 1, 1);

        var catVer = categories.FirstOrDefault()?.UpdatedAtUtc ?? categories.FirstOrDefault()?.CreatedAtUtc ?? DateTime.MinValue;
        var prodVer = products.FirstOrDefault()?.UpdatedAtUtc ?? products.FirstOrDefault()?.CreatedAtUtc ?? DateTime.MinValue;
        var recVer = recipes.FirstOrDefault()?.UpdatedAtUtc ?? recipes.FirstOrDefault()?.CreatedAtUtc ?? DateTime.MinValue;
        var desVer = designs.FirstOrDefault()?.UpdatedAtUtc ?? designs.FirstOrDefault()?.CreatedAtUtc ?? DateTime.MinValue;
        var cardVer = cards.FirstOrDefault()?.UpdatedAtUtc ?? cards.FirstOrDefault()?.CreatedAtUtc ?? DateTime.MinValue;
        var tutVer = tutorials.FirstOrDefault()?.UpdatedAtUtc ?? tutorials.FirstOrDefault()?.CreatedAtUtc ?? DateTime.MinValue;

        var catVerStr = $"{catVer:yyyyMMddHHmmss}-{catTotal}";
        var prodVerStr = $"{prodVer:yyyyMMddHHmmss}-{prodTotal}";
        var recVerStr = $"{recVer:yyyyMMddHHmmss}-{recTotal}";
        var desVerStr = $"{desVer:yyyyMMddHHmmss}-{desTotal}";
        var cardVerStr = $"{cardVer:yyyyMMddHHmmss}-{cardTotal}";
        var tutVerStr = $"{tutVer:yyyyMMddHHmmss}-{tutTotal}";

        var combined = $"{catVerStr}|{prodVerStr}|{recVerStr}|{desVerStr}|{cardVerStr}|{tutVerStr}";
        var hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(combined));
        var globalHash = Convert.ToHexString(hashBytes).ToLowerInvariant()[..16];

        return new LibraryManifestDto
        {
            CategoriesVersion = catVerStr,
            CategoriesCount = catTotal,
            ProductsVersion = prodVerStr,
            ProductsCount = prodTotal,
            RecipesVersion = recVerStr,
            RecipesCount = recTotal,
            DesignsVersion = desVerStr,
            DesignsCount = desTotal,
            CardsVersion = cardVerStr,
            CardsCount = cardTotal,
            TutorialsVersion = tutVerStr,
            TutorialsCount = tutTotal,
            GlobalManifestHash = globalHash,
            GeneratedAtUtc = DateTime.UtcNow
        };
    }

    #endregion

    #region Admin Management

    public async Task<LibraryCategoryDto> AdminCreateCategoryAsync(CreateOrUpdateLibraryCategoryRequest request)
    {
        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Name) : request.Slug.Trim().ToLowerInvariant();
        if (await _categoryRepo.SlugExistsAsync(slug))
            throw new InvalidOperationException($"Category slug '{slug}' already exists.");

        var category = new LibraryCategory(
            name: request.Name,
            slug: slug,
            description: request.Description,
            imageUrl: request.ImageUrl,
            iconKey: request.IconKey,
            parentCategoryId: request.ParentCategoryId,
            sortOrder: request.SortOrder);

        await _categoryRepo.AddAsync(category);
        return ToCategoryDto(category, 0);
    }

    public async Task<LibraryCategoryDto> AdminUpdateCategoryAsync(Guid id, CreateOrUpdateLibraryCategoryRequest request)
    {
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
            throw new KeyNotFoundException($"Library category '{id}' not found.");

        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Name) : request.Slug.Trim().ToLowerInvariant();
        if (await _categoryRepo.SlugExistsAsync(slug, id))
            throw new InvalidOperationException($"Category slug '{slug}' already exists.");

        category.Update(
            name: request.Name,
            slug: slug,
            description: request.Description,
            imageUrl: request.ImageUrl,
            iconKey: request.IconKey,
            parentCategoryId: request.ParentCategoryId,
            sortOrder: request.SortOrder);

        await _categoryRepo.UpdateAsync(category);
        var productCount = await _categoryRepo.GetProductCountAsync(category.Id);
        return ToCategoryDto(category, productCount);
    }

    public async Task AdminToggleCategoryStatusAsync(Guid id, bool isActive)
    {
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
            throw new KeyNotFoundException($"Library category '{id}' not found.");

        if (isActive) category.Activate();
        else category.Deactivate();

        await _categoryRepo.UpdateAsync(category);
    }

    public async Task AdminDeleteCategoryAsync(Guid id)
    {
        var category = await _categoryRepo.GetByIdAsync(id);
        if (category == null)
            throw new KeyNotFoundException($"Library category '{id}' not found.");

        await _categoryRepo.DeleteAsync(category);
    }

    public async Task<LibraryProductDetailDto> AdminCreateProductAsync(CreateOrUpdateLibraryProductRequest request)
    {
        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Name) : request.Slug.Trim().ToLowerInvariant();
        if (await _productRepo.SlugExistsAsync(slug))
            throw new InvalidOperationException($"Product slug '{slug}' already exists.");

        Enum.TryParse<UnitOfMeasure>(request.DefaultUnit, true, out var unit);

        var product = new LibraryProduct(
            name: request.Name,
            slug: slug,
            productType: ProductType.SingleFlower,
            standardUnit: unit == default ? UnitOfMeasure.Stem : unit,
            categoryId: request.CategoryId,
            standardSku: request.Slug,
            description: request.Description,
            referenceImageUrl: request.ImageUrl,
            thumbnailUrl: request.ImageUrl,
            searchKeywords: request.SearchKeywords,
            sortOrder: request.SortOrder);

        await _productRepo.AddAsync(product);
        return ToProductDetailDto(product);
    }

    public async Task<LibraryProductDetailDto> AdminUpdateProductAsync(Guid id, CreateOrUpdateLibraryProductRequest request)
    {
        var product = await _productRepo.GetByIdAsync(id);
        if (product == null)
            throw new KeyNotFoundException($"Library product '{id}' not found.");

        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Name) : request.Slug.Trim().ToLowerInvariant();
        if (await _productRepo.SlugExistsAsync(slug, id))
            throw new InvalidOperationException($"Product slug '{slug}' already exists.");

        Enum.TryParse<UnitOfMeasure>(request.DefaultUnit, true, out var unit);

        product.Update(
            name: request.Name,
            slug: slug,
            productType: product.ProductType,
            standardUnit: unit == default ? product.StandardUnit : unit,
            categoryId: request.CategoryId,
            standardSku: request.Slug,
            description: request.Description,
            referenceImageUrl: request.ImageUrl,
            thumbnailUrl: request.ImageUrl,
            searchKeywords: request.SearchKeywords,
            sortOrder: request.SortOrder);

        await _productRepo.UpdateAsync(product);
        return ToProductDetailDto(product);
    }

    public async Task AdminToggleProductStatusAsync(Guid id, bool isActive)
    {
        var product = await _productRepo.GetByIdAsync(id);
        if (product == null)
            throw new KeyNotFoundException($"Library product '{id}' not found.");

        if (isActive) product.Activate();
        else product.Deactivate();

        await _productRepo.UpdateAsync(product);
    }

    public async Task AdminDeleteProductAsync(Guid id)
    {
        var product = await _productRepo.GetByIdAsync(id);
        if (product == null)
            throw new KeyNotFoundException($"Library product '{id}' not found.");

        await _productRepo.DeleteAsync(product);
    }

    public async Task<LibraryRecipeDetailDto> AdminCreateRecipeAsync(CreateOrUpdateLibraryRecipeRequest request)
    {
        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Name) : request.Slug.Trim().ToLowerInvariant();
        if (await _recipeRepo.SlugExistsAsync(slug))
            throw new InvalidOperationException($"Recipe slug '{slug}' already exists.");

        var recipe = new LibraryRecipe(
            name: request.Name,
            slug: slug,
            description: request.Description,
            categoryId: request.CategoryId,
            imageUrl: request.ImageUrl,
            yieldQuantity: request.YieldQuantity <= 0 ? 1 : request.YieldQuantity,
            yieldUnit: request.YieldUnit,
            instructions: request.Instructions,
            preparationNotes: request.PreparationNotes,
            sortOrder: request.SortOrder);

        foreach (var item in request.Items.OrderBy(i => i.SortOrder))
        {
            recipe.AddItem(item.ProductName, item.Quantity, item.Unit, item.LibraryProductId, item.Notes, item.SortOrder);
        }

        await _recipeRepo.AddAsync(recipe);
        return ToRecipeDetailDto(recipe);
    }

    public async Task<LibraryRecipeDetailDto> AdminUpdateRecipeAsync(Guid id, CreateOrUpdateLibraryRecipeRequest request)
    {
        var recipe = await _recipeRepo.GetByIdAsync(id);
        if (recipe == null)
            throw new KeyNotFoundException($"Library recipe '{id}' not found.");

        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Name) : request.Slug.Trim().ToLowerInvariant();
        if (await _recipeRepo.SlugExistsAsync(slug, id))
            throw new InvalidOperationException($"Recipe slug '{slug}' already exists.");

        recipe.Update(
            name: request.Name,
            slug: slug,
            description: request.Description,
            categoryId: request.CategoryId,
            imageUrl: request.ImageUrl,
            yieldQuantity: request.YieldQuantity <= 0 ? 1 : request.YieldQuantity,
            yieldUnit: request.YieldUnit,
            instructions: request.Instructions,
            preparationNotes: request.PreparationNotes,
            sortOrder: request.SortOrder);

        recipe.ClearItems();
        foreach (var item in request.Items.OrderBy(i => i.SortOrder))
        {
            recipe.AddItem(item.ProductName, item.Quantity, item.Unit, item.LibraryProductId, item.Notes, item.SortOrder);
        }

        await _recipeRepo.UpdateAsync(recipe);
        return ToRecipeDetailDto(recipe);
    }

    public async Task AdminToggleRecipeStatusAsync(Guid id, bool isActive)
    {
        var recipe = await _recipeRepo.GetByIdAsync(id);
        if (recipe == null)
            throw new KeyNotFoundException($"Library recipe '{id}' not found.");

        if (isActive) recipe.Activate();
        else recipe.Deactivate();

        await _recipeRepo.UpdateAsync(recipe);
    }

    public async Task AdminDeleteRecipeAsync(Guid id)
    {
        var recipe = await _recipeRepo.GetByIdAsync(id);
        if (recipe == null)
            throw new KeyNotFoundException($"Library recipe '{id}' not found.");

        await _recipeRepo.DeleteAsync(recipe);
    }

    public async Task<LibraryDesignDetailDto> AdminCreateDesignAsync(CreateOrUpdateLibraryDesignRequest request)
    {
        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Title) : request.Slug.Trim().ToLowerInvariant();
        if (await _designRepo.SlugExistsAsync(slug))
            throw new InvalidOperationException($"Design slug '{slug}' already exists.");

        var design = new LibraryDesign(
            title: request.Title,
            slug: slug,
            description: request.Description,
            categoryId: request.CategoryId,
            imageUrl: request.ImageUrl,
            highResImageUrl: request.HighResImageUrl,
            thumbnailUrl: request.ThumbnailUrl,
            occasion: request.Occasion,
            style: request.Style,
            colorPalette: request.ColorPalette,
            flowerTypes: request.FlowerTypes,
            recipeId: request.RecipeId,
            searchKeywords: request.SearchKeywords,
            sortOrder: request.SortOrder);

        await _designRepo.AddAsync(design);
        return ToDesignDetailDto(design);
    }

    public async Task<LibraryDesignDetailDto> AdminUpdateDesignAsync(Guid id, CreateOrUpdateLibraryDesignRequest request)
    {
        var design = await _designRepo.GetByIdAsync(id);
        if (design == null)
            throw new KeyNotFoundException($"Library design '{id}' not found.");

        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Title) : request.Slug.Trim().ToLowerInvariant();
        if (await _designRepo.SlugExistsAsync(slug, id))
            throw new InvalidOperationException($"Design slug '{slug}' already exists.");

        design.Update(
            title: request.Title,
            slug: slug,
            description: request.Description,
            categoryId: request.CategoryId,
            imageUrl: request.ImageUrl,
            highResImageUrl: request.HighResImageUrl,
            thumbnailUrl: request.ThumbnailUrl,
            occasion: request.Occasion,
            style: request.Style,
            colorPalette: request.ColorPalette,
            flowerTypes: request.FlowerTypes,
            recipeId: request.RecipeId,
            searchKeywords: request.SearchKeywords,
            sortOrder: request.SortOrder);

        await _designRepo.UpdateAsync(design);
        return ToDesignDetailDto(design);
    }

    public async Task AdminToggleDesignStatusAsync(Guid id, bool isActive)
    {
        var design = await _designRepo.GetByIdAsync(id);
        if (design == null)
            throw new KeyNotFoundException($"Library design '{id}' not found.");

        if (isActive) design.Activate();
        else design.Deactivate();

        await _designRepo.UpdateAsync(design);
    }

    public async Task AdminDeleteDesignAsync(Guid id)
    {
        var design = await _designRepo.GetByIdAsync(id);
        if (design == null)
            throw new KeyNotFoundException($"Library design '{id}' not found.");

        await _designRepo.DeleteAsync(design);
    }

    public async Task<LibraryCardDetailDto> AdminCreateCardAsync(CreateOrUpdateLibraryCardRequest request)
    {
        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Title) : request.Slug.Trim().ToLowerInvariant();
        if (await _cardRepo.SlugExistsAsync(slug))
            throw new InvalidOperationException($"Card slug '{slug}' already exists.");

        var card = new LibraryCardTemplate(
            title: request.Title,
            slug: slug,
            content: request.Content,
            occasion: request.Occasion,
            tone: request.Tone,
            language: request.Language,
            categoryId: request.CategoryId,
            imageUrl: request.ImageUrl,
            searchKeywords: request.SearchKeywords,
            sortOrder: request.SortOrder);

        await _cardRepo.AddAsync(card);
        return ToCardDetailDto(card);
    }

    public async Task<LibraryCardDetailDto> AdminUpdateCardAsync(Guid id, CreateOrUpdateLibraryCardRequest request)
    {
        var card = await _cardRepo.GetByIdAsync(id);
        if (card == null)
            throw new KeyNotFoundException($"Library card '{id}' not found.");

        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Title) : request.Slug.Trim().ToLowerInvariant();
        if (await _cardRepo.SlugExistsAsync(slug, id))
            throw new InvalidOperationException($"Card slug '{slug}' already exists.");

        card.Update(
            title: request.Title,
            slug: slug,
            content: request.Content,
            occasion: request.Occasion,
            tone: request.Tone,
            language: request.Language,
            categoryId: request.CategoryId,
            imageUrl: request.ImageUrl,
            searchKeywords: request.SearchKeywords,
            sortOrder: request.SortOrder);

        await _cardRepo.UpdateAsync(card);
        return ToCardDetailDto(card);
    }

    public async Task AdminToggleCardStatusAsync(Guid id, bool isActive)
    {
        var card = await _cardRepo.GetByIdAsync(id);
        if (card == null)
            throw new KeyNotFoundException($"Library card '{id}' not found.");

        if (isActive) card.Activate();
        else card.Deactivate();

        await _cardRepo.UpdateAsync(card);
    }

    public async Task AdminDeleteCardAsync(Guid id)
    {
        var card = await _cardRepo.GetByIdAsync(id);
        if (card == null)
            throw new KeyNotFoundException($"Library card '{id}' not found.");

        await _cardRepo.DeleteAsync(card);
    }

    public async Task<LibraryTutorialDetailDto> AdminCreateTutorialAsync(CreateOrUpdateLibraryTutorialRequest request)
    {
        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Title) : request.Slug.Trim().ToLowerInvariant();
        if (await _tutorialRepo.SlugExistsAsync(slug))
            throw new InvalidOperationException($"Tutorial slug '{slug}' already exists.");

        var tutorial = new LibraryTutorial(
            title: request.Title,
            slug: slug,
            contentMarkdown: request.ContentMarkdown,
            summary: request.Summary,
            categoryId: request.CategoryId,
            videoUrl: request.VideoUrl,
            thumbnailUrl: request.ThumbnailUrl,
            difficultyLevel: request.DifficultyLevel,
            estimatedReadingMinutes: request.EstimatedReadingMinutes,
            tags: request.Tags,
            sortOrder: request.SortOrder);

        await _tutorialRepo.AddAsync(tutorial);
        return ToTutorialDetailDto(tutorial);
    }

    public async Task<LibraryTutorialDetailDto> AdminUpdateTutorialAsync(Guid id, CreateOrUpdateLibraryTutorialRequest request)
    {
        var tutorial = await _tutorialRepo.GetByIdAsync(id);
        if (tutorial == null)
            throw new KeyNotFoundException($"Library tutorial '{id}' not found.");

        var slug = string.IsNullOrWhiteSpace(request.Slug) ? Slugify(request.Title) : request.Slug.Trim().ToLowerInvariant();
        if (await _tutorialRepo.SlugExistsAsync(slug, id))
            throw new InvalidOperationException($"Tutorial slug '{slug}' already exists.");

        tutorial.Update(
            title: request.Title,
            slug: slug,
            contentMarkdown: request.ContentMarkdown,
            summary: request.Summary,
            categoryId: request.CategoryId,
            videoUrl: request.VideoUrl,
            thumbnailUrl: request.ThumbnailUrl,
            difficultyLevel: request.DifficultyLevel,
            estimatedReadingMinutes: request.EstimatedReadingMinutes,
            tags: request.Tags,
            sortOrder: request.SortOrder);

        await _tutorialRepo.UpdateAsync(tutorial);
        return ToTutorialDetailDto(tutorial);
    }

    public async Task AdminToggleTutorialStatusAsync(Guid id, bool isActive)
    {
        var tutorial = await _tutorialRepo.GetByIdAsync(id);
        if (tutorial == null)
            throw new KeyNotFoundException($"Library tutorial '{id}' not found.");

        if (isActive) tutorial.Activate();
        else tutorial.Deactivate();

        await _tutorialRepo.UpdateAsync(tutorial);
    }

    public async Task AdminDeleteTutorialAsync(Guid id)
    {
        var tutorial = await _tutorialRepo.GetByIdAsync(id);
        if (tutorial == null)
            throw new KeyNotFoundException($"Library tutorial '{id}' not found.");

        await _tutorialRepo.DeleteAsync(tutorial);
    }

    private static string Slugify(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return Guid.NewGuid().ToString("N")[..8];
        var clean = text.Trim().ToLowerInvariant();
        var sb = new StringBuilder();
        foreach (var c in clean)
        {
            if (char.IsLetterOrDigit(c)) sb.Append(c);
            else if (c is ' ' or '-' or '_') sb.Append('-');
        }
        var res = sb.ToString().Trim('-');
        return string.IsNullOrEmpty(res) ? Guid.NewGuid().ToString("N")[..8] : res;
    }

    #endregion

    #region Mappings

    private static LibraryCategoryDto ToCategoryDto(LibraryCategory c, int productCount) => new()
    {
        Id = c.Id,
        Name = c.Name,
        Slug = c.Slug,
        Description = c.Description,
        ImageUrl = c.ImageUrl,
        IconKey = c.IconKey,
        ParentCategoryId = c.ParentCategoryId,
        ParentCategoryName = c.ParentCategory?.Name,
        SortOrder = c.SortOrder,
        IsActive = c.IsActive,
        ProductCount = productCount,
        CreatedAtUtc = c.CreatedAtUtc,
        UpdatedAtUtc = c.UpdatedAtUtc
    };

    private static LibraryProductListItemDto ToProductListItemDto(LibraryProduct p) => new()
    {
        Id = p.Id,
        Name = p.Name,
        Slug = p.Slug,
        CategoryId = p.CategoryId,
        CategoryName = p.Category?.Name,
        ProductType = p.ProductType.ToString(),
        StandardUnit = p.StandardUnit.ToString(),
        StandardSku = p.StandardSku,
        ReferenceImageUrl = p.ReferenceImageUrl,
        ThumbnailUrl = p.ThumbnailUrl,
        SortOrder = p.SortOrder,
        IsActive = p.IsActive,
        Version = p.Version
    };

    private static LibraryProductDetailDto ToProductDetailDto(LibraryProduct p) => new()
    {
        Id = p.Id,
        Name = p.Name,
        Slug = p.Slug,
        CategoryId = p.CategoryId,
        CategoryName = p.Category?.Name,
        ProductType = p.ProductType.ToString(),
        StandardUnit = p.StandardUnit.ToString(),
        StandardSku = p.StandardSku,
        Description = p.Description,
        ReferenceImageUrl = p.ReferenceImageUrl,
        ThumbnailUrl = p.ThumbnailUrl,
        SearchKeywords = p.SearchKeywords,
        SortOrder = p.SortOrder,
        IsActive = p.IsActive,
        Version = p.Version,
        CreatedAtUtc = p.CreatedAtUtc,
        UpdatedAtUtc = p.UpdatedAtUtc
    };

    private static LibraryRecipeListItemDto ToRecipeListItemDto(LibraryRecipe r) => new()
    {
        Id = r.Id,
        Name = r.Name,
        Slug = r.Slug,
        Description = r.Description,
        CategoryId = r.CategoryId,
        CategoryName = r.Category?.Name,
        ImageUrl = r.ImageUrl,
        YieldQuantity = r.YieldQuantity,
        YieldUnit = r.YieldUnit,
        ItemCount = r.Items?.Count ?? 0,
        SortOrder = r.SortOrder,
        IsActive = r.IsActive,
        Version = r.Version
    };

    private static LibraryRecipeDetailDto ToRecipeDetailDto(LibraryRecipe r) => new()
    {
        Id = r.Id,
        Name = r.Name,
        Slug = r.Slug,
        Description = r.Description,
        CategoryId = r.CategoryId,
        CategoryName = r.Category?.Name,
        ImageUrl = r.ImageUrl,
        YieldQuantity = r.YieldQuantity,
        YieldUnit = r.YieldUnit,
        Instructions = r.Instructions,
        PreparationNotes = r.PreparationNotes,
        SortOrder = r.SortOrder,
        IsActive = r.IsActive,
        Version = r.Version,
        CreatedAtUtc = r.CreatedAtUtc,
        UpdatedAtUtc = r.UpdatedAtUtc,
        Items = r.Items?.Select(ToRecipeItemDto).ToList() ?? new()
    };

    private static LibraryRecipeItemDto ToRecipeItemDto(LibraryRecipeItem i) => new()
    {
        Id = i.Id,
        LibraryProductId = i.LibraryProductId,
        LibraryProductName = i.LibraryProduct?.Name,
        ProductName = i.ProductNameSnapshot,
        Quantity = i.Quantity,
        Unit = i.Unit,
        Notes = i.Notes,
        SortOrder = i.SortOrder
    };

    private static LibraryDesignListItemDto ToDesignListItemDto(LibraryDesign d) => new()
    {
        Id = d.Id,
        Title = d.Title,
        Slug = d.Slug,
        Description = d.Description,
        CategoryId = d.CategoryId,
        CategoryName = d.Category?.Name,
        ImageUrl = d.ImageUrl,
        HighResImageUrl = d.HighResImageUrl,
        ThumbnailUrl = d.ThumbnailUrl,
        Occasion = d.Occasion,
        Style = d.Style,
        ColorPalette = d.ColorPalette,
        FlowerTypes = d.FlowerTypes,
        RecipeId = d.RecipeId,
        RecipeName = d.Recipe?.Name,
        SortOrder = d.SortOrder,
        IsActive = d.IsActive,
        Version = d.Version
    };

    private static LibraryDesignDetailDto ToDesignDetailDto(LibraryDesign d) => new()
    {
        Id = d.Id,
        Title = d.Title,
        Slug = d.Slug,
        Description = d.Description,
        CategoryId = d.CategoryId,
        CategoryName = d.Category?.Name,
        ImageUrl = d.ImageUrl,
        HighResImageUrl = d.HighResImageUrl,
        ThumbnailUrl = d.ThumbnailUrl,
        Occasion = d.Occasion,
        Style = d.Style,
        ColorPalette = d.ColorPalette,
        FlowerTypes = d.FlowerTypes,
        RecipeId = d.RecipeId,
        RecipeName = d.Recipe?.Name,
        SearchKeywords = d.SearchKeywords,
        SortOrder = d.SortOrder,
        IsActive = d.IsActive,
        Version = d.Version,
        CreatedAtUtc = d.CreatedAtUtc,
        UpdatedAtUtc = d.UpdatedAtUtc
    };

    private static LibraryCardListItemDto ToCardListItemDto(LibraryCardTemplate c) => new()
    {
        Id = c.Id,
        Title = c.Title,
        Slug = c.Slug,
        Content = c.Content,
        Occasion = c.Occasion,
        Tone = c.Tone,
        Language = c.Language,
        CategoryId = c.CategoryId,
        CategoryName = c.Category?.Name,
        ImageUrl = c.ImageUrl,
        SortOrder = c.SortOrder,
        IsActive = c.IsActive,
        Version = c.Version
    };

    private static LibraryCardDetailDto ToCardDetailDto(LibraryCardTemplate c) => new()
    {
        Id = c.Id,
        Title = c.Title,
        Slug = c.Slug,
        Content = c.Content,
        Occasion = c.Occasion,
        Tone = c.Tone,
        Language = c.Language,
        CategoryId = c.CategoryId,
        CategoryName = c.Category?.Name,
        ImageUrl = c.ImageUrl,
        SearchKeywords = c.SearchKeywords,
        SortOrder = c.SortOrder,
        IsActive = c.IsActive,
        Version = c.Version,
        CreatedAtUtc = c.CreatedAtUtc,
        UpdatedAtUtc = c.UpdatedAtUtc
    };

    private static LibraryTutorialListItemDto ToTutorialListItemDto(LibraryTutorial t) => new()
    {
        Id = t.Id,
        Title = t.Title,
        Slug = t.Slug,
        Summary = t.Summary,
        CategoryId = t.CategoryId,
        CategoryName = t.Category?.Name,
        VideoUrl = t.VideoUrl,
        ThumbnailUrl = t.ThumbnailUrl,
        DifficultyLevel = t.DifficultyLevel,
        EstimatedReadingMinutes = t.EstimatedReadingMinutes,
        Tags = t.Tags,
        SortOrder = t.SortOrder,
        IsActive = t.IsActive,
        Version = t.Version
    };

    private static LibraryTutorialDetailDto ToTutorialDetailDto(LibraryTutorial t) => new()
    {
        Id = t.Id,
        Title = t.Title,
        Slug = t.Slug,
        Summary = t.Summary,
        ContentMarkdown = t.ContentMarkdown,
        CategoryId = t.CategoryId,
        CategoryName = t.Category?.Name,
        VideoUrl = t.VideoUrl,
        ThumbnailUrl = t.ThumbnailUrl,
        DifficultyLevel = t.DifficultyLevel,
        EstimatedReadingMinutes = t.EstimatedReadingMinutes,
        Tags = t.Tags,
        SortOrder = t.SortOrder,
        IsActive = t.IsActive,
        Version = t.Version,
        CreatedAtUtc = t.CreatedAtUtc,
        UpdatedAtUtc = t.UpdatedAtUtc
    };

    private static LibraryFestivalListItemDto ToFestivalListItemDto(LibraryFestival f) => new()
    {
        Id = f.Id,
        Name = f.Name,
        Slug = f.Slug,
        FestivalDate = f.FestivalDate,
        Month = f.Month,
        Day = f.Day,
        Description = f.Description,
        IsRecurring = f.IsRecurring,
        FlowerDemands = f.FlowerDemands,
        ImageUrl = f.ImageUrl,
        SortOrder = f.SortOrder,
        IsActive = f.IsActive,
        Version = f.Version
    };

    private static LibraryFestivalDetailDto ToFestivalDetailDto(LibraryFestival f) => new()
    {
        Id = f.Id,
        Name = f.Name,
        Slug = f.Slug,
        FestivalDate = f.FestivalDate,
        Month = f.Month,
        Day = f.Day,
        Description = f.Description,
        IsRecurring = f.IsRecurring,
        FlowerDemands = f.FlowerDemands,
        SearchKeywords = f.SearchKeywords,
        ImageUrl = f.ImageUrl,
        SortOrder = f.SortOrder,
        IsActive = f.IsActive,
        Version = f.Version,
        CreatedAtUtc = f.CreatedAtUtc,
        UpdatedAtUtc = f.UpdatedAtUtc
    };

    private static LibraryWeddingDateListItemDto ToWeddingDateListItemDto(LibraryWeddingDate w) => new()
    {
        Id = w.Id,
        Title = w.Title,
        Slug = w.Slug,
        WeddingDate = w.WeddingDate,
        Tithi = w.Tithi,
        Nakshatra = w.Nakshatra,
        Notes = w.Notes,
        Season = w.Season,
        DemandLevel = w.DemandLevel,
        SortOrder = w.SortOrder,
        IsActive = w.IsActive,
        Version = w.Version
    };

    private static LibraryWeddingDateDetailDto ToWeddingDateDetailDto(LibraryWeddingDate w) => new()
    {
        Id = w.Id,
        Title = w.Title,
        Slug = w.Slug,
        WeddingDate = w.WeddingDate,
        Tithi = w.Tithi,
        Nakshatra = w.Nakshatra,
        Notes = w.Notes,
        Season = w.Season,
        DemandLevel = w.DemandLevel,
        SearchKeywords = w.SearchKeywords,
        SortOrder = w.SortOrder,
        IsActive = w.IsActive,
        Version = w.Version,
        CreatedAtUtc = w.CreatedAtUtc,
        UpdatedAtUtc = w.UpdatedAtUtc
    };

    #endregion
}
