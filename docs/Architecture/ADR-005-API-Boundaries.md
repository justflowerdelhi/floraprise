# ADR-005: API boundaries are explicit

- Status: Accepted
- Date: 31-Jul-2026
- Decision: APIs between products will be explicit, versioned, and documented. No implicit coupling through shared controllers, shared services, or shared persistence.

## Reason

Implicit API coupling hides ownership and makes future changes risky.

## Consequences

- Each product exposes its own API surface.
- Cross-product integration is via documented HTTP contracts.
- SharedKernel contains only contract-safe abstractions when necessary.
