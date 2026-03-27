# Developer Audit Report (2026-03-27)

## Scope
This report summarizes the current implementation state, recent fixes, and pending work so a new developer can continue without rediscovery.

## Build Health
- Backend build: PASS (`dotnet build Sumpooj.API/Sumpooj.API.csproj -c Debug`)
- Frontend build: PASS (`cd sumpooj-web && npm run build`)
- Frontend production bundle generated successfully (Vite 7.3.0)

## Recently Completed (Verified)

### 1) Authentication reliability
- Login no longer fails if audit logging fails.
- File: `Sumpooj.API/Controllers/AuthController.cs`
- Change: wrapped successful-login audit write in try/catch, logs warning but returns login success.

### 2) Expense accounting now posts double-entry
- Expense creation now writes both source expense row and journal impact.
- File: `Sumpooj.API/Controllers/AccountingController.cs`
- Change:
  - Debit expense account
  - Credit cash/asset account
  - Validates amount > 0
  - Auto-creates missing expense/cash accounts

### 3) Journal endpoint runtime fix
- Fixed EF/Npgsql projection issue from `ToString("yyyy-MM-dd")` in SQL projection.
- File: `Sumpooj.API/Controllers/AccountingController.cs`
- Change: materialize entities first, then map/format date in memory.

### 4) Profit & Loss COGS classification fix
- COGS now separated from generic expenses in P&L.
- File: `Sumpooj.API/Controllers/AccountingController.cs`
- Change: classify COGS by account code/name (`5000`, `Cost of Goods Sold`, `COGS`) before generic `Expense` bucket.

### 5) POS sale accounting now includes COGS posting
- POS sale posting now includes inventory cost movement.
- File: `Sumpooj.Application/UseCases/OrderService.cs`
- Change:
  - Existing: Dr payment account, Cr sales revenue
  - Added: Dr COGS (5000), Cr Inventory (1200)
  - COGS value: sum(product.CostPrice * quantity) for inventory-tracked products

### 6) Accounting frontend stabilization
- File: `sumpooj-web/src/modules/accounting/accounting.service.ts`
  - Removed silent catch in `getJournalEntries` and `addExpense`
  - Added `cogs` mapping in `getProfitLossReportData`
- File: `sumpooj-web/src/modules/accounting/pages/JournalViewer.tsx`
  - Added error state display and refresh button
  - Added `SALE` filter option
- File: `sumpooj-web/src/modules/accounting/pages/JournalEntryModal.tsx`
  - Fixed crash when API returns flat entry (no `lines` array)

### 7) Events list runtime fix
- File: `sumpooj-web/src/pages/events/EventList.tsx`
- Change:
  - Normalize backend enums (`Inquiry`, `InProduction`, etc.) to frontend enum shape (`INQUIRY`, `IN_PRODUCTION`, etc.)
  - Added safe config fallbacks to prevent runtime crashes on unknown values
  - Added reverse mapping when sending filters to backend

### 8) Gift card designer background fallback
- File: `sumpooj-web/src/pages/gift-cards/GiftCardBuilder.tsx`
- Change: show gradient fallback in style tiles when template image is missing.

### 9) Staff attendance UI enhancement
- File: `sumpooj-web/src/pages/staff/StaffAttendance.tsx`
- Change:
  - Added staff dropdown selector
  - Added check-in/check-out time fields (read-only display)
  - Kept current check-in/check-out API integration

## Functional Data Paths (Important)

### Staff attendance
- Frontend page: `sumpooj-web/src/pages/staff/StaffAttendance.tsx`
- API: `api/staff/attendance/today`, `api/staff/attendance/{staffId}/check-in`, `api/staff/attendance/{recordId}/check-out`
- Controller: `Sumpooj.API/Controllers/StaffAttendanceController.cs`
- Storage entity/table:
  - Entity: `Sumpooj.Domain/Entities/StaffAttendanceRecord.cs`
  - DbSet: `Sumpooj.Infrastructure/Persistence/SumpoojDbContext.cs` (`StaffAttendanceRecords`)

## Pending / Recommended Next Work

### High priority
1. Add tests for accounting posting rules
- No automated tests currently cover expense and POS journal posting combinations.
- Add integration tests for:
  - expense posting (Dr expense / Cr cash)
  - POS posting (Dr payment / Cr revenue / Dr COGS / Cr inventory)
  - P&L COGS separation

2. Standardize frontend event DTO mapping layer
- `EventList.tsx` currently normalizes API data in-page.
- Move this logic into `sumpooj-web/src/api/event.api.ts` mapper utilities so all event pages share a single contract conversion.

3. Attendance time input semantics
- Current UI uses `type="time"` read-only fields for display.
- Consider plain text fields or formatted labels to avoid browser time-control quirks for non-editable values.

### Medium priority
4. Gift card asset completion
- Folder `sumpooj-web/public/gift-cards/backgrounds` is missing expected template images.
- Current fallback works, but production look improves with actual image assets.

5. Expense manager UX consistency
- Expense list currently shows placeholders for payment method/location due to backend DTO mismatch.
- Extend backend DTO or frontend mapping if these values are required in reporting views.

6. Replace remaining silent error patterns
- Some older modules still rely on silent fallback behavior.
- Prefer explicit user-visible errors for data integrity-sensitive flows.

### Low priority
7. SourceLink warnings in backend build
- Non-blocking warnings appear due to missing source control info in build environment.

## Known Operational Notes
- API launch often fails with `address already in use` on port 5148 if old process is still alive.
- Recommended local workflow:
  - Stop process listening on 5148 before `dotnet run`
  - Or run with a different port profile for parallel sessions

## Quick Validation Checklist for New Developer
1. Login works even if audit write fails.
2. Create expense -> appears in Expenses + Journal + Trial Balance.
3. Create POS sale -> Journal has 4 lines (payment, revenue, COGS, inventory).
4. P&L shows non-zero COGS when sale with cost exists.
5. `/accounting/journal` opens without runtime error.
6. `/events` loads and filters without enum/config crashes.
7. `/gift-cards/designer` style tiles are visible.
8. `/staff/attendance` shows dropdown + check-in/out times and actions.

## Summary
Core accounting integrity and multiple runtime UI blockers were fixed. The project is build-green on backend and frontend. Remaining work is mostly test coverage, contract cleanup, and UX polish rather than hard blockers.
