# Floraprise Architecture Constitution v1.0

This document is the governance source of truth for Floraprise. It governs architecture decisions for future AI sessions, Copilot prompts, and development work.

## 1. Vision

Floraprise is a platform of independent products.

Each product owns:
- Business logic
- Database
- Authentication
- Deployment
- Configuration
- Background jobs
- APIs

No product owns another product.

## 2. Product Ownership Matrix

- ERP owns: Companies, Accounting, Inventory, CRM, Production, ERP Delivery, ERP Subscription
- Mobile owns: Mobile Users, Mobile Licenses, Mobile Devices, Mobile Orders, Mobile Delivery, Mobile Subscription, Mobile Devices
- Driver owns: Driver login, Driver GPS, Driver tasks
- Customer owns: Customer tracking, Customer notifications
- Administration owns: ERP administration

This matrix is the reference whenever someone asks where a feature should go.

## 3. Architecture Decision Record (ADR)

Significant architectural decisions must be recorded with an ADR ID.

### ADR-001
Mobile is an independent platform.

- Status: Accepted
- Reason: Different lifecycle and deployment than ERP
- Date: 31-Jul-2026

### ADR-002
ERP remains stable.

### ADR-003
Authentication is product-owned and independent.

### ADR-004
Subscriptions are product-owned and independent.

### ADR-005
Communication between products occurs through documented REST APIs only.

## 4. Feature Placement Rule

Every new feature must answer three questions before coding:

1. Who owns this feature?
2. Which product owns the data?
3. Which product owns the business rules?

If the answers are unclear, stop and decide before implementation.

## 5. Change Approval Levels

### Can implement without approval
- New Mobile controller
- New Mobile service
- New Mobile table
- Mobile UI
- Mobile API

### Must ask first
- ERP database changes
- ERP authentication changes
- ERP subscriptions
- SharedKernel changes
- API contract changes

## 6. Repository Rules

Never allow:
- Mobile -> ERP.Infrastructure
- ERP -> Mobile.Infrastructure

Only allow:
- Mobile -> SharedKernel
- ERP -> SharedKernel

## 7. AI Working Rules

Every Copilot or AI session should begin with:

1. Explain your understanding.
2. Explain which product owns this feature.
3. List every existing file you intend to modify.
4. Explain why each modification is necessary.
5. Wait for approval.

## 8. Success Criteria

The next milestone is not "Mobile works". The milestone is:

- Mobile builds independently
- Mobile deploys independently
- Mobile authenticates independently
- Mobile database initializes independently
- ERP remains unchanged
- No compile-time dependency between Mobile and ERP

Only after all six are true should feature migration begin.

## 9. Architectural Governance Rule

Architecture has higher priority than implementation.

If any implementation conflicts with this architecture document:
- do not implement it,
- stop,
- explain the conflict,
- and ask for approval.

Never guess. Never "improve" the architecture. This document is the source of truth.
