namespace Sumpooj.Application.Mobile;

/// <summary>
/// Authoritative pricing matrix and gateway resolution for Floraprise Mobile Subscriptions.
/// India: INR via PayU (Quarterly ₹4,999 / 90d, Half-Yearly ₹8,999 / 180d, Annual ₹14,999 / 365d)
/// USA: USD via PayPal (Quarterly $179 / 90d, Half-Yearly $329 / 180d, Annual $599 / 365d)
/// UAE: AED via PayPal (Quarterly AED 649 / 90d, Half-Yearly AED 1,199 / 180d, Annual AED 2,199 / 365d)
/// Fallback: India pricing (INR / PayU)
/// </summary>
public static class SubscriptionCountryPricing
{
    public sealed record PlanPricing(
        decimal Amount,
        string Currency,
        int DurationDays,
        MobilePaymentGatewayType Gateway);

    public sealed record CountryPricingConfig(
        string CountryCode,
        string CurrencyCode,
        MobilePaymentGatewayType DefaultGateway,
        IReadOnlyDictionary<string, PlanPricing> Plans);

    private static readonly Dictionary<string, CountryPricingConfig> CountryConfigs = new(StringComparer.OrdinalIgnoreCase)
    {
        ["IN"] = new(
            CountryCode: "IN",
            CurrencyCode: "INR",
            DefaultGateway: MobilePaymentGatewayType.PayU,
            Plans: new Dictionary<string, PlanPricing>(StringComparer.OrdinalIgnoreCase)
            {
                ["QUARTERLY"] = new(4999m, "INR", 90, MobilePaymentGatewayType.PayU),
                ["HALF-YEARLY"] = new(8999m, "INR", 180, MobilePaymentGatewayType.PayU),
                ["HALFYEARLY"] = new(8999m, "INR", 180, MobilePaymentGatewayType.PayU),
                ["ANNUAL"] = new(14999m, "INR", 365, MobilePaymentGatewayType.PayU),
                ["YEARLY"] = new(14999m, "INR", 365, MobilePaymentGatewayType.PayU)
            }
        ),
        ["US"] = new(
            CountryCode: "US",
            CurrencyCode: "USD",
            DefaultGateway: MobilePaymentGatewayType.PayPal,
            Plans: new Dictionary<string, PlanPricing>(StringComparer.OrdinalIgnoreCase)
            {
                ["QUARTERLY"] = new(179m, "USD", 90, MobilePaymentGatewayType.PayPal),
                ["HALF-YEARLY"] = new(329m, "USD", 180, MobilePaymentGatewayType.PayPal),
                ["HALFYEARLY"] = new(329m, "USD", 180, MobilePaymentGatewayType.PayPal),
                ["ANNUAL"] = new(599m, "USD", 365, MobilePaymentGatewayType.PayPal),
                ["YEARLY"] = new(599m, "USD", 365, MobilePaymentGatewayType.PayPal)
            }
        ),
        ["AE"] = new(
            CountryCode: "AE",
            CurrencyCode: "AED",
            DefaultGateway: MobilePaymentGatewayType.PayPal,
            Plans: new Dictionary<string, PlanPricing>(StringComparer.OrdinalIgnoreCase)
            {
                ["QUARTERLY"] = new(649m, "AED", 90, MobilePaymentGatewayType.PayPal),
                ["HALF-YEARLY"] = new(1199m, "AED", 180, MobilePaymentGatewayType.PayPal),
                ["HALFYEARLY"] = new(1199m, "AED", 180, MobilePaymentGatewayType.PayPal),
                ["ANNUAL"] = new(2199m, "AED", 365, MobilePaymentGatewayType.PayPal),
                ["YEARLY"] = new(2199m, "AED", 365, MobilePaymentGatewayType.PayPal)
            }
        )
    };

    public static string NormalizeCountryCode(string? countryOrRegion)
    {
        if (string.IsNullOrWhiteSpace(countryOrRegion)) return "IN";
        var trimmed = countryOrRegion.Trim().ToUpperInvariant();
        if (trimmed is "IN" or "IND" or "INDIA") return "IN";
        if (trimmed is "US" or "USA" or "UNITED STATES" or "UNITED STATES OF AMERICA") return "US";
        if (trimmed is "AE" or "UAE" or "UNITED ARAB EMIRATES" or "DUBAI" or "ABU DHABI") return "AE";

        // Handle ISO region prefixes (e.g. IN-DL, IN-MH, US-CA, US-NY, AE-DU, AE-AZ)
        if (trimmed.StartsWith("IN-") || trimmed.StartsWith("IN_") || trimmed.StartsWith("IND-")) return "IN";
        if (trimmed.StartsWith("US-") || trimmed.StartsWith("US_") || trimmed.StartsWith("USA-")) return "US";
        if (trimmed.StartsWith("AE-") || trimmed.StartsWith("AE_") || trimmed.StartsWith("UAE-")) return "AE";

        return "IN";
    }

    public static string NormalizeBillingCycle(string? billingCycle)
    {
        if (string.IsNullOrWhiteSpace(billingCycle)) return "ANNUAL";
        var cycle = billingCycle.Trim().ToUpperInvariant();
        return cycle switch
        {
            "QUARTERLY" or "QUARTER" or "3MONTHS" or "3_MONTHS" or "3M" => "QUARTERLY",
            "HALF-YEARLY" or "HALFYEARLY" or "HALF_YEARLY" or "SEMI-ANNUAL" or "SEMIANNUAL" or "6MONTHS" or "6_MONTHS" or "6M" => "HALF-YEARLY",
            "ANNUAL" or "YEARLY" or "1YEAR" or "12MONTHS" or "12_MONTHS" or "1Y" or "12M" => "ANNUAL",
            _ => "ANNUAL"
        };
    }

    public static int BillingCycleToDays(string? billingCycle)
    {
        var cycle = NormalizeBillingCycle(billingCycle);
        return cycle switch
        {
            "QUARTERLY" => 90,
            "HALF-YEARLY" => 180,
            "ANNUAL" => 365,
            _ => 365
        };
    }

    public static CountryPricingConfig GetConfig(string? countryOrRegion)
    {
        var code = NormalizeCountryCode(countryOrRegion);
        return CountryConfigs.TryGetValue(code, out var cfg) ? cfg : CountryConfigs["IN"];
    }

    public static PlanPricing ResolvePricing(string? countryOrRegion, string? billingCycle)
    {
        var cfg = GetConfig(countryOrRegion);
        var cycle = NormalizeBillingCycle(billingCycle);
        if (cfg.Plans.TryGetValue(cycle, out var plan))
            return plan;

        return cfg.Plans["ANNUAL"];
    }

    public static PlanPricing ResolvePricingWithFallback(string? countryOrRegion, string? currencyCode, string? billingCycle)
    {
        var country = NormalizeCountryCode(countryOrRegion);
        if (string.IsNullOrWhiteSpace(countryOrRegion) && !string.IsNullOrWhiteSpace(currencyCode))
        {
            var cur = currencyCode.Trim().ToUpperInvariant();
            if (cur == "USD") country = "US";
            else if (cur == "AED") country = "AE";
            else if (cur == "INR") country = "IN";
        }
        return ResolvePricing(country, billingCycle);
    }

    public static (string BillingCycle, PlanPricing Pricing)? MatchPlanByAmount(string? countryOrRegion, decimal amount, string? currency)
    {
        var cfg = GetConfig(countryOrRegion);
        foreach (var (cycle, plan) in cfg.Plans)
        {
            var amountMatches = decimal.Round(plan.Amount, 2) == decimal.Round(amount, 2);
            var currencyMatches = string.IsNullOrWhiteSpace(currency) ||
                                  string.Equals(plan.Currency, currency.Trim(), StringComparison.OrdinalIgnoreCase);
            if (amountMatches && currencyMatches)
            {
                return (cycle, plan);
            }
        }

        return null;
    }

    public static bool MatchesPrice(string? countryOrRegion, string? billingCycle, decimal amount, string? currency)
    {
        var expected = ResolvePricing(countryOrRegion, billingCycle);
        var amountMatches = decimal.Round(expected.Amount, 2) == decimal.Round(amount, 2);
        var currencyMatches = string.IsNullOrWhiteSpace(currency) ||
                              string.Equals(expected.Currency, currency.Trim(), StringComparison.OrdinalIgnoreCase);
        return amountMatches && currencyMatches;
    }
}
