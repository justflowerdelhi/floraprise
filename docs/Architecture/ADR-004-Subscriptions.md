# ADR-004: Subscriptions are product-owned

- Status: Accepted
- Date: 31-Jul-2026
- Decision: Subscription handling belongs to the product that owns the user relationship and business lifecycle.

## Reason

Subscription rules differ by product and should not be forced into ERP or shared across products without a dedicated contract.

## Consequences

- Mobile subscription logic stays with Mobile.
- ERP subscription logic stays with ERP.
- Cross-product subscription coordination must use explicit APIs.
