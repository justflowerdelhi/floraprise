using System.Net.Http.Json;
using Sumpooj.Blazor.Models;

namespace Sumpooj.Blazor.Services;

public class CustomerApiService
{
    private readonly HttpClient _http;

    public CustomerApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<PagedResult<CustomerDto>> SearchAsync(
        string? query,
        int page,
        int pageSize)
    {
        var url =
            $"api/customers/search?query={query}&page={page}&pageSize={pageSize}";

        return await _http.GetFromJsonAsync<PagedResult<CustomerDto>>(url)
            ?? new PagedResult<CustomerDto>();
    }

    public async Task CreateAsync(CreateCustomerRequest request)
    {
        var response = await _http.PostAsJsonAsync(
            "api/customers", request);

        response.EnsureSuccessStatusCode();
    }

}
