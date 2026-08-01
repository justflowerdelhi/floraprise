namespace Sumpooj.Blazor.Data;

public class OwnerState
{
    public string SearchQuery { get; set; } = string.Empty;
    public event Action? OnSearchChanged;

    public void SetSearch(string query)
    {
        SearchQuery = query;
        OnSearchChanged?.Invoke();
    }
}
