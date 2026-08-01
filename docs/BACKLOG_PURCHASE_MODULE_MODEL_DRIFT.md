# Backlog Item: Purchase Module Model Drift

Type: Technical debt / data integrity hardening
Priority: High
Status: Open
Independence: This item is independent of mobile licensing/subscription work.

## Problem Statement
There is suspected drift between the Purchase module entity model (especially `PurchaseOrderItem` and related aggregates) and the actual database schema/migrations. This can lead to subtle runtime failures, silent data truncation/defaulting, incorrect totals, and inaccurate reporting.

## Why This Is Separate From Mobile Licensing
- Purchase module drift impacts procurement, inventory valuation, and accounting paths.
- Mobile licensing work concerns auth/subscription/license flows and does not own purchase-schema correctness.
- Ownership, test surface, and rollback plans are distinct.

## Suspected Drift Patterns
- Missing or mismatched columns (nullability, precision/scale, defaults).
- Type mismatches between EF mappings and SQL schema.
- Navigation/relationship cardinality mismatch.
- Migration history not fully aligned with runtime model snapshot.

## Scope
- In scope:
  - `PurchaseOrder`, `PurchaseOrderItem`, taxes/discount fields, unit/multi-unit fields, supplier linkage, stock-impact fields.
  - EF entity configuration and migration snapshots affecting purchase tables.
  - SQL schema validation for all purchase-related tables.
- Out of scope:
  - New purchase business features.
  - Mobile API/license/subscription behavior.

## Investigation Plan
1. Build an authoritative field-by-field map: EF model vs live schema.
2. Validate data types, lengths, precision/scale, nullability, defaults, indexes, and FK constraints.
3. Reproduce any runtime/model binding errors in integration tests.
4. Generate minimal corrective migration(s) and rollback script(s).
5. Validate no regression in purchase flows and accounting postings.

## Acceptance Criteria
- Zero drift for purchase module entities against schema in target environment.
- All purchase integration tests pass (create/edit/receive/cancel/repost/accounting impact).
- No runtime warnings/errors due to missing/invalid purchase columns.
- Corrective migration reviewed and applied in staging with rollback tested.
- Audit note added with before/after schema comparison.

## Risks
- Existing production data may violate intended constraints.
- Corrective migration may require data backfill/transformation.
- Index/constraint corrections can lock large tables if not planned.

## Deliverables
- Drift report (model vs schema matrix).
- SQL migration + rollback scripts.
- Test evidence from staging.
- Deployment runbook for low-risk rollout window.

## Estimate
- Investigation: 0.5-1 day
- Fix + migration prep: 0.5-1 day
- Staging validation + sign-off: 0.5 day
Total: 1.5-2.5 days
