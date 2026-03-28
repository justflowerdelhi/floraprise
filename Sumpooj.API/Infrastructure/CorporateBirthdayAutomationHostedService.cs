using Sumpooj.Application.Companies;
using Sumpooj.Application.UseCases;

namespace Sumpooj.API.Infrastructure;

public class CorporateBirthdayAutomationHostedService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<CorporateBirthdayAutomationHostedService> _logger;
    private readonly IConfiguration _configuration;

    public CorporateBirthdayAutomationHostedService(
        IServiceProvider serviceProvider,
        ILogger<CorporateBirthdayAutomationHostedService> logger,
        IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _configuration = configuration;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var enabled = _configuration.GetValue("Corporate:EnableBirthdayAutomation", false);
        if (!enabled)
        {
            _logger.LogInformation("Corporate birthday automation is disabled.");
            return;
        }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Corporate birthday automation run failed.");
            }

            var now = DateTime.UtcNow;
            var next = now.Date.AddDays(1).AddHours(1);
            var delay = next - now;
            if (delay < TimeSpan.Zero)
                delay = TimeSpan.FromHours(24);

            await Task.Delay(delay, stoppingToken);
        }
    }

    private async Task RunOnceAsync(CancellationToken cancellationToken)
    {
        using var scope = _serviceProvider.CreateScope();
        var companyService = scope.ServiceProvider.GetRequiredService<ICompanyService>();
        var corporateService = scope.ServiceProvider.GetRequiredService<CorporateService>();

        var companies = await companyService.GetAllAsync();
        foreach (var company in companies.Where(c => c.IsActive))
        {
            if (cancellationToken.IsCancellationRequested)
                break;

            var result = await corporateService.RunBirthdayAutomationAsync(company.Id, DateTime.UtcNow.Date);
            _logger.LogInformation(
                "Corporate birthday automation: Company {CompanyId}, created={Created}, dup={Dup}, missingDefault={MissingDefault}, missingAddress={MissingAddress}",
                company.Id,
                result.CreatedOrders,
                result.SkippedDuplicate,
                result.SkippedMissingDefaultProduct,
                result.SkippedNoAddress);
        }
    }
}
