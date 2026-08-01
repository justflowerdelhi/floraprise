using System.Net.Http.Json;

namespace Sumpooj.Blazor.Services;

public class SubscriptionApiService
{
    private readonly HttpClient _http;

    public SubscriptionApiService(IHttpClientFactory factory)
    {
        _http = factory.CreateClient("Api");
    }

    public async Task<DashboardDto> GetDashboardAsync()
    {
        var response = await _http.GetAsync("api/platform/mobile-admin/dashboard");
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<DashboardDto>() ?? new();
    }

    public async Task<List<SubscriberDto>> GetSubscribersAsync()
    {
        var response = await _http.GetAsync("api/platform/mobile-admin/customers");
        response.EnsureSuccessStatusCode();
        var result = await response.Content.ReadFromJsonAsync<MobileAdminCustomerPagedResultDto>();
        return result?.Items ?? new();
    }

    public async Task<bool> ExtendLicenseAsync(Guid mobileUserId, Guid companyId, int extendByDays)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/customers/{mobileUserId}/extend", new { extendByDays, companyId });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> RenewSubscriptionAsync(Guid licenseId, int extendByDays)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/licenses/{licenseId}/extend", new { extendByDays });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> SuspendLicenseAsync(Guid mobileUserId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/customers/{mobileUserId}/suspend", new { companyId });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> ActivateLicenseAsync(Guid mobileUserId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/customers/{mobileUserId}/activate", new { companyId });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> HardLockAsync(Guid licenseId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/licenses/{licenseId}/suspend", new { companyId });
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> ActivateAsync(Guid licenseId, Guid companyId)
    {
        var response = await _http.PostAsJsonAsync($"api/platform/mobile-admin/licenses/{licenseId}/activate", new { companyId });
        return response.IsSuccessStatusCode;
    }
}


public class DashboardDto
{
    public int ActiveUsers { get; set; }
    public int TrialUsers { get; set; }
    public int ActiveSubscriptions { get; set; }
    public int RenewalsDue { get; set; }
    public decimal Revenue { get; set; }
    public int OnlineDevices { get; set; }
    public int TrialExpiringToday { get; set; }
    public int RenewalsDueToday { get; set; }
    public int DevicesOffline7Days { get; set; }
    public int FailedPayments { get; set; }
    public int RecentlySuspendedAccounts { get; set; }
    public int NewCustomersLast7Days { get; set; }
}

public class SubscriberDto
{
    public Guid MobileUserId { get; set; }
    public Guid CompanyId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string BusinessName { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string UserStatus { get; set; } = string.Empty;
    public string SubscriptionStatus { get; set; } = string.Empty;
    public string PlanCode { get; set; } = string.Empty;
    public string PlanName { get; set; } = string.Empty;
    public DateTime? TrialEndUtc { get; set; }
    public DateTime? SubscriptionEndUtc { get; set; }
    public int RemainingDays { get; set; }
    public int TotalDevices { get; set; }
    public int OnlineDevices { get; set; }
}

public class MobileAdminCustomerPagedResultDto
{
    public List<SubscriberDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}
