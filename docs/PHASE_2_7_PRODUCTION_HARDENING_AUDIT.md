# Phase 2.7 Production Hardening Audit (Mobile Platform)

Date: 2026-07-28
Scope: Hardening only (no new business features)
Status: Partially complete, compile-stable, one external package-risk blocker remains

## Executive Result
- Build status: PASS (`FloristERP.sln`, Debug)
- Target score: >=90
- Achieved score: 88/100
- Release decision: HOLD for production rollout until the remaining high-severity transitive vulnerability is resolved or formally risk-accepted with compensating controls.

## Evidence Snapshot
- Full solution build succeeded after hardening changes.
- Vulnerability scan (`dotnet list ... --vulnerable --include-transitive`) shows one remaining issue:
  - `Microsoft.OpenApi` 2.0.0 (transitive in `Sumpooj.API`) - High - GHSA-v5pm-xwqc-g5wc
- Mobile endpoint documentation metrics (controller scan):
  - HTTP endpoints: 30
  - XML `<summary>` count: 30
  - Route `Name="Mobile..."` count: 30
  - `[Authorize(...)]` count on protected endpoints: 8

## Scorecard
- OpenAPI Quality: 94/100
  - Added endpoint XML summaries/remarks/examples.
  - Added operation naming consistency via route names and fallback operation transformer.
  - Added standard problem responses for 400/401/403/404/409/500 (`application/problem+json`).
- Security: 76/100
  - Explicit JWT bearer scheme on protected mobile endpoints.
  - Policy-based protection preserved (`CompanyOnly`).
  - Structured ProblemDetails contract in base controller and global exception handling.
  - Deduction: one unresolved high transitive vulnerability.
- Runtime Reliability: 93/100
  - Health checks enforce cancellation/timeouts (2s) and structured diagnostics.
  - Database startup/backoff logic with environment-aware behavior.
  - Correlation and mobile request telemetry fields added.
- Performance/Operational Efficiency: 88/100
  - No speculative micro-optimizations; focused on measurable reliability and startup behavior.
  - Db retry/backoff and command timeout added.
- Documentation/Operational Readiness: 90/100
  - API behavior and error contracts substantially clearer.

Overall: 88/100

## Hardening Delivered

### 1) Error Contract Standardization
- Global `ProblemDetails` setup and exception handler in API startup.
- `traceId` consistently attached for debugging correlation.
- Mobile base controller standardized 4xx/5xx `ProblemDetails` response annotations.

### 2) OpenAPI Quality and Consistency
- Added OpenAPI document transformer for Bearer scheme.
- Added operation transformer for:
  - fallback `OperationId`
  - fallback summary/description
  - standard problem responses
  - request/response example hints in descriptions
- Added XML docs and route name uniqueness patterns across mobile controllers.

### 3) Security Declaration Clarity
- Protected endpoints explicitly use JWT auth scheme + policy.
- 200 response types explicitly declared for core mobile operations.

### 4) Health Checks and Startup Resilience
- DB connectivity and pending migration checks with 2s timeout.
- Circuit-like guard to avoid repeated expensive failed probes.
- Startup DB connectivity/backoff helper with environment-aware fail/continue behavior.

### 5) Structured Logging for Mobile Endpoints
- Added logging scope/fields for mobile API requests including:
  - `CorrelationId`, `CompanyId`, `UserId`, `DeviceId`, `SubscriptionId`, `Endpoint`, `DurationMs`, `StatusCode`
- Added `X-Correlation-ID` response header.

### 6) NuGet/Dependency Hardening
- `Sumpooj.Infrastructure` upgraded package set and added explicit `System.Security.Cryptography.Xml` 10.0.10 remediation.
- `Sumpooj.API` core package updates completed (JWT/OpenAPI/EF design/Scalar) and XML docs generation enabled.

## NuGet Remediation Table (Confirmed)

| Project | Package | Previous | Current | Risk/Breaking Change Note |
|---|---|---:|---:|---|
| Sumpooj.Infrastructure | Microsoft.AspNetCore.Identity.EntityFrameworkCore | 10.0.1 | 10.0.10 | Patch-level, low risk |
| Sumpooj.Infrastructure | Microsoft.EntityFrameworkCore | 10.0.1 | 10.0.10 | Patch-level, low risk |
| Sumpooj.Infrastructure | Microsoft.EntityFrameworkCore.Design | 10.0.1 | 10.0.10 | Tooling patch-level |
| Sumpooj.Infrastructure | Microsoft.EntityFrameworkCore.Tools | 10.0.1 | 10.0.10 | Tooling patch-level |
| Sumpooj.Infrastructure | Microsoft.Extensions.Http | 10.0.4 | 10.0.10 | Patch-level |
| Sumpooj.Infrastructure | Npgsql.EntityFrameworkCore.PostgreSQL | 10.0.0 | 10.0.3 | Patch-level, low risk |
| Sumpooj.Infrastructure | System.Security.Cryptography.Xml | transitive vulnerable baseline | 10.0.10 (explicit) | Vulnerability remediated |
| Sumpooj.API | Microsoft.AspNetCore.Authentication.JwtBearer | baseline updated | 10.0.10 | Patch-level |
| Sumpooj.API | Microsoft.AspNetCore.OpenApi | baseline updated | 10.0.10 | Patch-level |
| Sumpooj.API | Microsoft.EntityFrameworkCore.Design | baseline updated | 10.0.10 | Tooling patch-level |
| Sumpooj.API | Scalar.AspNetCore | baseline updated | 2.16.16 | Minor/patch ecosystem change |

Notes:
- Attempted explicit pin `Microsoft.OpenApi` 3.9.0 removes vulnerability from scan but breaks compile with current ASP.NET OpenAPI source-generated code compatibility in this solution.

## Remaining Blocker
- Project: `Sumpooj.API`
- Package: `Microsoft.OpenApi` 2.0.0 (transitive)
- Severity: High
- Advisory: GHSA-v5pm-xwqc-g5wc
- Why unresolved now:
  - Explicit pin to 3.9.0 causes compile failures (OpenAPI source generation/type compatibility mismatch).
  - Keeping compile-safe package graph currently retains vulnerable transitive dependency.

## Mitigation Options
1. Preferred: upgrade/downgrade the OpenAPI dependency chain as a coherent set (ASP.NET OpenAPI + Scalar + related generators) in a dedicated compatibility branch until `Microsoft.OpenApi` >= 3.9.0 is consumed without compile breaks.
2. Short-term: keep current compile-safe state, restrict public OpenAPI exposure, and document temporary risk acceptance with expiry date and owner.
3. Add release gate: CI fails on high severity vulnerable packages unless a signed exception record exists.

## Conclusion
Phase 2.7 delivered substantial production hardening and achieved a stable build with improved API documentation, runtime resilience, and error contract consistency. The >=90 score target is not yet met due to one unresolved high transitive vulnerability tied to OpenAPI package-chain compatibility. Current objective evidence supports 88/100 and a production hold until dependency-chain remediation is completed.
