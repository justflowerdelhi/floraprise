# Floraprise Development Charter v1.0

## Project Status

Floraprise is now in the PRODUCT STABILIZATION phase.

Priority is no longer adding features quickly.

Priority is protecting existing workflows while improving usability.

## Rule 1: Zero Regression

Never break an existing working feature.

Existing functionality always has higher priority than new functionality.

If a new implementation introduces regression, fix it immediately, or rollback ONLY the new implementation.

Never leave the application in a partially working state.

## Rule 2: Smallest Change Principle

Modify the smallest possible number of files.

Prefer extending existing code instead of replacing it.

Avoid architectural changes.

## Rule 3: Reuse First

Before creating new code, search for existing:

- Provider
- Repository
- Widget
- Dialog
- Service
- Helper
- Model

Reuse existing implementation whenever possible.

Do not duplicate logic.

## Rule 4: One Sprint = One Objective

Every sprint must have ONE clearly defined objective.

Never combine unrelated improvements.

Complete.

Verify.

Report.

Stop.

## Rule 5: No Hidden Improvements

Do not implement "while I was here..." changes.

Do not refactor unrelated code.

Do not optimize unrelated modules.

Do only what was requested.

## Rule 6: Protect User Experience

Do not redesign existing workflows without approval.

Improve existing workflows.

Do not surprise users.

## Rule 7: Flutter First

If task is for Flutter, do not modify:

- ERP
- ASP.NET
- API
- Database

unless explicitly requested.

## Rule 8: Business Rules Are Sacred

Never modify:

- Inventory Logic
- Accounting Rules
- Subscription
- Licensing
- POS Calculation
- Order Processing
- Recipe Logic
- Tax
- Payment Calculation

without explicit approval.

## Rule 9: Validation

Every sprint must include:

- flutter analyze
- Build
- Startup verification
- Focused manual verification

Then stop.

## Rule 10: Report Format

Use this report format:

- Sprint
- Status
- Risk Level
- Changed Files (Current Sprint Only)
- Existing Features Verified
- Manual Test Matrix
- Known Environment Issues
- Pre-existing Modified Files
- Stop

## Rule 11: Change Approval Policy

### Category A: Internal Fixes

Examples:

- Bug Fix
- Performance
- Crash
- Logging
- Security

Approval: NOT REQUIRED.

### Category B: User Experience Changes

Examples:

- Buttons
- Dialogs
- Navigation
- Workflow
- New Screens
- Permission Flow
- POS Behaviour

Approval: REQUIRED BEFORE IMPLEMENTATION.

### Category C: Business Rule Changes

Examples:

- Inventory
- Accounting
- Subscription
- Payment
- Reports
- Pricing
- Tax
- Day Close
- Customer Ledger

Approval: EXPLICIT APPROVAL REQUIRED.

Never change automatically.

## Rule 12: Florist First Principle

Always choose the implementation that is easiest for a florist to understand.

Operational simplicity is more important than technical elegance.

## Rule 13: Risk Level

Every sprint must report one of:

- LOW
- MEDIUM
- HIGH

Include an explanation.

## Rule 14: Stop Rule

After implementation, validation, and reporting, STOP.

Wait for next instruction.

Never continue improving other modules automatically.

## Semantic Versioning

Use this release structure:

- v1.0.x: Bug Fixes, Stability, Compatibility
- v1.1.x: Product Polish, User Experience, Workflow Improvements
- v1.2.x: Operational Features
- v2.x: Major Product Capabilities
