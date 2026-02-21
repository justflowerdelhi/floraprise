using Microsoft.Extensions.DependencyInjection;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Payments;

/// <summary>
/// Factory for creating payment gateway instances
/// </summary>
public interface IPaymentGatewayFactory
{
    /// <summary>
    /// Create and initialize a gateway instance for the given configuration
    /// </summary>
    Task<IPaymentGateway> CreateAsync(PaymentGatewayConfig config);
    
    /// <summary>
    /// Get supported gateway types
    /// </summary>
    IEnumerable<PaymentGatewayType> GetSupportedGateways();
}

public class PaymentGatewayFactory : IPaymentGatewayFactory
{
    private readonly IServiceProvider _serviceProvider;
    private readonly Dictionary<PaymentGatewayType, Type> _gatewayTypes = new();

    public PaymentGatewayFactory(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
        RegisterGateways();
    }

    private void RegisterGateways()
    {
        // Register all gateway implementations

        // India
        _gatewayTypes[PaymentGatewayType.Razorpay] = typeof(Gateways.RazorpayGateway);
        _gatewayTypes[PaymentGatewayType.PayU] = typeof(Gateways.PayUGateway);
        _gatewayTypes[PaymentGatewayType.Cashfree] = typeof(Gateways.CashfreeGateway);

        // USA
        _gatewayTypes[PaymentGatewayType.Stripe] = typeof(Gateways.StripeGateway);
        _gatewayTypes[PaymentGatewayType.Square] = typeof(Gateways.SquareGateway);
        _gatewayTypes[PaymentGatewayType.PayPal] = typeof(Gateways.PayPalGateway);

        // GCC
        _gatewayTypes[PaymentGatewayType.PayTabs] = typeof(Gateways.PayTabsGateway);
        _gatewayTypes[PaymentGatewayType.HyperPay] = typeof(Gateways.HyperPayGateway);
        _gatewayTypes[PaymentGatewayType.TapPayments] = typeof(Gateways.TapGateway);
        _gatewayTypes[PaymentGatewayType.CheckoutCom] = typeof(Gateways.CheckoutGateway);
    }

    public async Task<IPaymentGateway> CreateAsync(PaymentGatewayConfig config)
    {
        if (!_gatewayTypes.TryGetValue(config.GatewayType, out var gatewayType))
        {
            throw new NotSupportedException($"Payment gateway '{config.GatewayType}' is not supported");
        }

        var gateway = (IPaymentGateway)ActivatorUtilities.CreateInstance(_serviceProvider, gatewayType);
        await gateway.InitializeAsync(config);
        
        return gateway;
    }

    public IEnumerable<PaymentGatewayType> GetSupportedGateways() => _gatewayTypes.Keys;
}
