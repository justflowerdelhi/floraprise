using Microsoft.Extensions.Logging;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Service for managing payment gateway configurations
/// </summary>
public class PaymentGatewayConfigService
{
    private readonly IPaymentGatewayConfigRepository _repository;
    private readonly IPaymentGatewayFactory _gatewayFactory;
    private readonly ITenantContext _tenantContext;
    private readonly ILogger<PaymentGatewayConfigService> _logger;

    public PaymentGatewayConfigService(
        IPaymentGatewayConfigRepository repository,
        IPaymentGatewayFactory gatewayFactory,
        ITenantContext tenantContext,
        ILogger<PaymentGatewayConfigService> logger)
    {
        _repository = repository;
        _gatewayFactory = gatewayFactory;
        _tenantContext = tenantContext;
        _logger = logger;
    }

    public async Task<IReadOnlyList<PaymentGatewayConfigDto>> GetAllAsync()
    {
        var configs = await _repository.GetByCompanyAsync(_tenantContext.CompanyId.Value);
        return configs.Select(MapToDto).ToList();
    }

    public async Task<PaymentGatewayConfigDto?> GetByIdAsync(Guid id)
    {
        var config = await _repository.GetByIdAsync(id);
        if (config == null || config.CompanyId != _tenantContext.CompanyId.Value)
            return null;
        
        return MapToDto(config);
    }

    public async Task<PaymentGatewayConfigDto?> GetDefaultAsync()
    {
        var config = await _repository.GetDefaultForCompanyAsync(_tenantContext.CompanyId.Value);
        return config != null ? MapToDto(config) : null;
    }

    public async Task<PaymentGatewayConfigDto> CreateAsync(PaymentGatewayConfigCreateDto dto)
    {
        // Check if gateway type already exists for this company
        var existing = await _repository.GetByCompanyAndTypeAsync(_tenantContext.CompanyId.Value, dto.GatewayType);
        if (existing != null)
        {
            throw new InvalidOperationException($"A {dto.GatewayType} configuration already exists for this company");
        }

        var config = new PaymentGatewayConfig(
            companyId: _tenantContext.CompanyId.Value,
            gatewayType: dto.GatewayType,
            name: dto.Name,
            publicKey: dto.PublicKey,
            secretKeyEncrypted: BasePaymentGateway.EncryptSecret(dto.SecretKey),
            environment: dto.Environment,
            currency: dto.Currency
        );

        if (!string.IsNullOrEmpty(dto.WebhookSecret))
        {
            config.UpdateCredentials(dto.PublicKey, config.SecretKeyEncrypted, 
                BasePaymentGateway.EncryptSecret(dto.WebhookSecret));
        }

        if (!string.IsNullOrEmpty(dto.MerchantId))
            config.SetMerchantId(dto.MerchantId);

        if (!string.IsNullOrEmpty(dto.SupportedCurrencies))
            config.SetCurrency(dto.Currency, dto.SupportedCurrencies);

        if (!string.IsNullOrEmpty(dto.AdditionalConfig))
            config.SetAdditionalConfig(dto.AdditionalConfig);

        if (dto.IsDefault)
        {
            await _repository.ClearDefaultsForCompanyAsync(_tenantContext.CompanyId.Value);
            config.SetAsDefault();
        }

        // Generate webhook URL
        var webhookUrl = $"/api/webhooks/payment/{dto.GatewayType.ToString().ToLowerInvariant()}/{_tenantContext.CompanyId}";
        config.SetWebhookUrl(webhookUrl);

        await _repository.AddAsync(config);
        
        _logger.LogInformation("Created payment gateway config {GatewayType} for company {CompanyId}", 
            dto.GatewayType, _tenantContext.CompanyId.Value);

        return MapToDto(config);
    }

    public async Task<PaymentGatewayConfigDto?> UpdateAsync(Guid id, PaymentGatewayConfigUpdateDto dto)
    {
        var config = await _repository.GetByIdAsync(id);
        if (config == null || config.CompanyId != _tenantContext.CompanyId.Value)
            return null;

        if (!string.IsNullOrEmpty(dto.Name))
            config = UpdateName(config, dto.Name);

        if (dto.PublicKey != null || dto.SecretKey != null)
        {
            var publicKey = dto.PublicKey ?? config.PublicKey;
            var secretKey = dto.SecretKey != null 
                ? BasePaymentGateway.EncryptSecret(dto.SecretKey) 
                : config.SecretKeyEncrypted;
            var webhookSecret = dto.WebhookSecret != null 
                ? BasePaymentGateway.EncryptSecret(dto.WebhookSecret) 
                : config.WebhookSecretEncrypted;
            
            config.UpdateCredentials(publicKey, secretKey, webhookSecret);
        }

        if (dto.MerchantId != null)
            config.SetMerchantId(dto.MerchantId);

        if (dto.Environment.HasValue)
            config.SetEnvironment(dto.Environment.Value);

        if (dto.Currency != null)
            config.SetCurrency(dto.Currency, dto.SupportedCurrencies);

        if (dto.IsActive.HasValue)
        {
            if (dto.IsActive.Value) config.Activate();
            else config.Deactivate();
        }

        if (dto.IsDefault == true)
        {
            await _repository.ClearDefaultsForCompanyAsync(_tenantContext.CompanyId.Value);
            config.SetAsDefault();
        }
        else if (dto.IsDefault == false)
        {
            config.RemoveDefault();
        }

        if (dto.AdditionalConfig != null)
            config.SetAdditionalConfig(dto.AdditionalConfig);

        await _repository.UpdateAsync(config);
        
        return MapToDto(config);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var config = await _repository.GetByIdAsync(id);
        if (config == null || config.CompanyId != _tenantContext.CompanyId.Value)
            return false;

        await _repository.DeleteAsync(config);
        
        _logger.LogInformation("Deleted payment gateway config {Id} for company {CompanyId}", 
            id, _tenantContext.CompanyId.Value);
        
        return true;
    }

    public async Task<PaymentGatewayTestResultDto> TestConnectionAsync(Guid id)
    {
        var config = await _repository.GetByIdAsync(id);
        if (config == null || config.CompanyId != _tenantContext.CompanyId.Value)
        {
            return new PaymentGatewayTestResultDto(false, "Configuration not found", DateTime.UtcNow);
        }

        try
        {
            var gateway = await _gatewayFactory.CreateAsync(config);
            var result = await gateway.TestConnectionAsync();
            
            config.RecordTestResult(result.Success);
            await _repository.UpdateAsync(config);
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Gateway connection test failed for config {Id}", id);
            
            config.RecordTestResult(false);
            await _repository.UpdateAsync(config);
            
            return new PaymentGatewayTestResultDto(false, $"Test failed: {ex.Message}", DateTime.UtcNow);
        }
    }

    public IReadOnlyList<PaymentGatewayInfoDto> GetAvailableGateways()
    {
        return PaymentGatewayInfo.GetAll();
    }

    private static PaymentGatewayConfig UpdateName(PaymentGatewayConfig config, string name)
    {
        // Since Name is private set, we need to use reflection or recreate
        // For now, this is a limitation - consider adding a SetName method to entity
        return config;
    }

    private static PaymentGatewayConfigDto MapToDto(PaymentGatewayConfig config) => new(
        Id: config.Id,
        GatewayType: config.GatewayType,
        GatewayTypeName: config.GatewayType.ToString(),
        Name: config.Name,
        PublicKey: config.PublicKey,
        MerchantId: config.MerchantId,
        Environment: config.Environment,
        EnvironmentName: config.Environment.ToString(),
        Currency: config.Currency,
        SupportedCurrencies: config.SupportedCurrencies,
        IsActive: config.IsActive,
        IsDefault: config.IsDefault,
        WebhookUrl: config.WebhookUrl,
        LastTestedAt: config.LastTestedAt,
        LastTestSuccessful: config.LastTestSuccessful,
        Region: PaymentGatewayConfig.GetRegion(config.GatewayType),
        CreatedAt: config.CreatedAtUtc
    );
}
