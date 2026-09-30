namespace Sumpooj.Application.Library;

public class LibraryManifestDto
{
    public string CategoriesVersion { get; set; } = string.Empty;
    public int CategoriesCount { get; set; }

    public string ProductsVersion { get; set; } = string.Empty;
    public int ProductsCount { get; set; }

    public string RecipesVersion { get; set; } = string.Empty;
    public int RecipesCount { get; set; }

    public string DesignsVersion { get; set; } = string.Empty;
    public int DesignsCount { get; set; }

    public string CardsVersion { get; set; } = string.Empty;
    public int CardsCount { get; set; }

    public string TutorialsVersion { get; set; } = string.Empty;
    public int TutorialsCount { get; set; }

    public string GlobalManifestHash { get; set; } = string.Empty;
    public DateTime GeneratedAtUtc { get; set; } = DateTime.UtcNow;
}
