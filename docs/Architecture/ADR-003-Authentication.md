# ADR-003: Authentication is product-owned

- Status: Accepted
- Date: 31-Jul-2026
- Decision: Authentication belongs to each product and must not be shared implicitly between ERP and Mobile.

## Reason

Authentication flows, identity models, token issuance, and login experience differ by product. A shared auth model creates unnecessary coupling.

## Consequences

- Mobile uses its own auth flow.
- ERP uses its own auth flow.
- SharedKernel may contain only contract-safe abstractions if needed.
