# Floraprise Enterprise Solution Structure v1.0

This document is a design proposal only. It does not create projects, modify the existing solution, or implement runtime code.

## 1. Architectural Principles

1. Every product must be independently deployable.
2. Every product owns its own domain, database, authentication, configuration, and APIs.
3. Shared code must be limited to contract-safe and infrastructure-safe abstractions.
4. Cross-product communication must occur through versioned APIs or events.
5. No product may depend on another product’s runtime implementation.
6. ERP remains the operational core; Mobile, Driver, Customer, Relay, Website, Analytics, Admin Portal, and API Gateway are independent product lines.
7. The platform must support 10 years of growth without forcing all products into one deployment model.
8. Each product must be able to move to its own repository, CI/CD pipeline, and hosting environment later without rewriting the architecture.

---

## 2. Global Solution Layout

```text
/platform
  /shared
    /SharedKernel
      /Contracts
      /Common
      /Abstractions
  /products
    /erp
      /ERP.sln
      /src
        /ERP.API
        /ERP.Application
        /ERP.Domain
        /ERP.Infrastructure
        /ERP.Contracts
        /ERP.Core
    /mobile
      /Mobile.sln
      /src
        /Mobile.API
        /Mobile.Application
        /Mobile.Domain
        /Mobile.Infrastructure
        /Mobile.Contracts
        /Mobile.Core
    /driver
      /Driver.sln
      /src
        /Driver.API
        /Driver.Application
        /Driver.Domain
        /Driver.Infrastructure
        /Driver.Contracts
        /Driver.Core
    /customer
      /Customer.sln
      /src
        /Customer.API
        /Customer.Application
        /Customer.Domain
        /Customer.Infrastructure
        /Customer.Contracts
        /Customer.Core
    /relay
      /Relay.sln
      /src
        /Relay.API
        /Relay.Application
        /Relay.Domain
        /Relay.Infrastructure
        /Relay.Contracts
        /Relay.Core
    /website
      /Website.sln
      /src
        /Website.API
        /Website.Application
        /Website.Domain
        /Website.Infrastructure
        /Website.Contracts
        /Website.Core
    /analytics
      /Analytics.sln
      /src
        /Analytics.API
        /Analytics.Application
        /Analytics.Domain
        /Analytics.Infrastructure
        /Analytics.Contracts
        /Analytics.Core
    /adminportal
      /AdminPortal.sln
      /src
        /AdminPortal.API
        /AdminPortal.Application
        /AdminPortal.Domain
        /AdminPortal.Infrastructure
        /AdminPortal.Contracts
        /AdminPortal.Core
    /apigateway
      /ApiGateway.sln
      /src
        /ApiGateway.API
        /ApiGateway.Application
        /ApiGateway.Domain
        /ApiGateway.Infrastructure
        /ApiGateway.Contracts
        /ApiGateway.Core
```

---

## 3. Common Project Model for Every Product

Each product uses the same layered shape:

- API: HTTP entry point, routing, auth, validation, controllers, middleware.
- Application: use cases, orchestration, command/query handlers, business services.
- Domain: entities, value objects, domain rules, aggregates.
- Infrastructure: persistence, external SDKs, queues, cache integration, file storage.
- Contracts: DTOs, request/response models, API schemas, event contracts.
- Core: shared product primitives such as result types, exceptions, common helpers, and cross-cutting abstractions.

### Standard Dependency Direction

```text
API -> Application -> Domain -> Core
API -> Contracts
Application -> Contracts
Infrastructure -> Domain / Application / Contracts
```

---

## 4. Global Dependency Matrix

The following references are permitted.

| Project | Allowed References |
|---|---|
| Product.API | Product.Application, Product.Contracts, Product.Core, SharedKernel.Contracts |
| Product.Application | Product.Domain, Product.Contracts, Product.Core, SharedKernel.Contracts |
| Product.Domain | Product.Core, SharedKernel.Contracts |
| Product.Infrastructure | Product.Domain, Product.Application, Product.Contracts, Product.Core, SharedKernel.Contracts |
| Product.Contracts | SharedKernel.Contracts |
| Product.Core | SharedKernel.Contracts |

### Forbidden References

- No product API may reference another product’s API project.
- No product application layer may reference another product’s application layer.
- No product infrastructure layer may reference another product’s infrastructure layer.
- No product may reference a database context belonging to another product.
- No product may assume another product’s internal services are available by direct class reference.

---

## 5. Product-by-Product Design

### ERP

#### 1. Visual Studio Solution Structure

- Solution: ERP.sln
- Product boundary: operational ERP platform for company, inventory, accounting, orders, and back-office processes.

#### 2. Projects

- ERP.API
- ERP.Application
- ERP.Domain
- ERP.Infrastructure
- ERP.Contracts
- ERP.Core

#### 3. Folder Structure

```text
ERP.sln
src/
  ERP.API/
    Controllers/
    Middleware/
    Filters/
    wwwroot/
  ERP.Application/
    Orders/
    Inventory/
    Accounting/
    Customers/
    Employees/
  ERP.Domain/
    Aggregates/
    Entities/
    ValueObjects/
    Events/
  ERP.Infrastructure/
    Persistence/
    Integrations/
    Messaging/
    Cache/
  ERP.Contracts/
    Requests/
    Responses/
    Events/
  ERP.Core/
    ResultPattern/
    Exceptions/
    Extensions/
```

#### 4. Dependency Diagram

```text
ERP.API -> ERP.Application -> ERP.Domain -> ERP.Core
ERP.API -> ERP.Contracts
ERP.Application -> ERP.Contracts
ERP.Infrastructure -> ERP.Domain / ERP.Application / ERP.Contracts
```

#### 5. Allowed Project References

- ERP.API -> ERP.Application, ERP.Contracts, ERP.Core, SharedKernel.Contracts
- ERP.Application -> ERP.Domain, ERP.Contracts, ERP.Core, SharedKernel.Contracts
- ERP.Domain -> ERP.Core, SharedKernel.Contracts
- ERP.Infrastructure -> ERP.Domain, ERP.Application, ERP.Contracts, ERP.Core, SharedKernel.Contracts
- ERP.Contracts -> SharedKernel.Contracts
- ERP.Core -> SharedKernel.Contracts

#### 6. Forbidden Project References

- ERP.API must not reference Mobile.API, Driver.API, Customer.API, Relay.API, Website.API, Analytics.API, AdminPortal.API, or ApiGateway.API.
- ERP.Infrastructure must not reference another product’s persistence layer.

#### 7. Authentication Boundary

- ERP uses its own identity domain.
- Session-based or token-based authentication for employees and admin users.
- Authentication is scoped to ERP user accounts and ERP permissions.

#### 8. Database Boundary

- ERP owns its own database.
- Core tables include Company, Account, LedgerEntry, Order, InventoryItem, TaxRule, Supplier, Employee, and ApprovalWorkflow.

#### 9. API Boundary

- Base route: /api/v1/erp/
- Examples: /api/v1/erp/orders, /api/v1/erp/inventory, /api/v1/erp/accounting

#### 10. Configuration Strategy

- Product-specific appsettings and environment-specific overrides.
- Secrets are loaded from a secure secret store.
- ERP configuration never depends on Mobile configuration values.

#### 11. Logging Strategy

- Structured logs with correlation IDs.
- Audit logs for financial and operational actions.
- Separate log streams for application, security, and audit events.

#### 12. Caching Strategy

- Cache ERP read-heavy reference data such as tax rules, inventory snapshots, and company settings.
- Use distributed cache for shared instances across ERP nodes.

#### 13. Background Job Strategy

- Background workers for invoicing, reconciliation, stock updates, and batch operations.
- Use a product-owned queue and worker pool.

#### 14. Deployment Strategy

- Host ERP behind its own domain.
- Recommended: erp.floraprise.com
- Independent deployment pipeline and scale rules.

#### 15. Versioning Strategy

- API versioning via URL versioning.
- Contract versioning for DTO changes.
- Database migrations versioned per product.

#### 16. Testing Strategy

- Unit tests for domain rules.
- Integration tests for persistence and service orchestration.
- Contract tests for API payloads.

#### 17. Future Scaling Strategy

- Scale ERP independently from other products.
- Add read replicas and worker nodes without affecting customer-facing products.

---

### Mobile

#### 1. Visual Studio Solution Structure

- Solution: Mobile.sln
- Product boundary: customer-facing mobile application platform for mobile users, devices, subscriptions, and mobile workflows.

#### 2. Projects

- Mobile.API
- Mobile.Application
- Mobile.Domain
- Mobile.Infrastructure
- Mobile.Contracts
- Mobile.Core

#### 3. Folder Structure

```text
Mobile.sln
src/
  Mobile.API/
    Controllers/
    Middleware/
  Mobile.Application/
    Auth/
    Devices/
    Subscriptions/
    Orders/
  Mobile.Domain/
    Aggregates/
    Entities/
    ValueObjects/
  Mobile.Infrastructure/
    Persistence/
    Push/
    Cache/
  Mobile.Contracts/
    Requests/
    Responses/
    Events/
  Mobile.Core/
    ResultPattern/
    Exceptions/
```

#### 4. Dependency Diagram

```text
Mobile.API -> Mobile.Application -> Mobile.Domain -> Mobile.Core
Mobile.API -> Mobile.Contracts
Mobile.Application -> Mobile.Contracts
Mobile.Infrastructure -> Mobile.Domain / Mobile.Application / Mobile.Contracts
```

#### 5. Allowed Project References

- Mobile.API -> Mobile.Application, Mobile.Contracts, Mobile.Core, SharedKernel.Contracts
- Mobile.Application -> Mobile.Domain, Mobile.Contracts, Mobile.Core, SharedKernel.Contracts
- Mobile.Domain -> Mobile.Core, SharedKernel.Contracts
- Mobile.Infrastructure -> Mobile.Domain, Mobile.Application, Mobile.Contracts, Mobile.Core, SharedKernel.Contracts
- Mobile.Contracts -> SharedKernel.Contracts
- Mobile.Core -> SharedKernel.Contracts

#### 6. Forbidden Project References

- Mobile.API must not reference ERP.API or any other product API directly.
- Mobile.Infrastructure must not reference ERP persistence components.

#### 7. Authentication Boundary

- Mobile owns its own authentication flows, sessions, device trust, and token issuance rules.
- Mobile auth is isolated from ERP identity.

#### 8. Database Boundary

- Mobile owns its own database.
- Core tables include MobileUser, MobileDevice, MobileSession, MobileSubscription, MobileOrderDraft, MobileDeviceToken.

#### 9. API Boundary

- Base route: /api/v1/mobile/
- Examples: /api/v1/mobile/auth/login, /api/v1/mobile/orders, /api/v1/mobile/subscriptions

#### 10. Configuration Strategy

- Product-specific settings for push notifications, mobile app metadata, and feature flags.
- Mobile secrets are stored independently from ERP.

#### 11. Logging Strategy

- Structured logs for authentication, subscription states, and device events.
- Device-specific correlation logs for support diagnostics.

#### 12. Caching Strategy

- Cache subscription status, feature flags, and mobile session metadata.
- Use short-lived cache entries to avoid stale mobile state.

#### 13. Background Job Strategy

- Queue-based workers for sync jobs, notification dispatching, and subscription refreshes.

#### 14. Deployment Strategy

- Host Mobile independently.
- Recommended: mobile.floraprise.com

#### 15. Versioning Strategy

- Versioned mobile APIs and mobile contract versions.
- Keep backwards compatibility for mobile clients.

#### 16. Testing Strategy

- Unit tests for mobile workflows and domain rules.
- Integration tests around device and subscription lifecycle.
- End-to-end tests for authentication and push flows.

#### 17. Future Scaling Strategy

- Mobile can scale independently with dedicated API and worker capacity.
- Separate queues allow burst handling for notifications and sync jobs.

---

### Driver

#### 1. Visual Studio Solution Structure

- Solution: Driver.sln
- Product boundary: driver app, assignments, route execution, location updates, and delivery coordination.

#### 2. Projects

- Driver.API
- Driver.Application
- Driver.Domain
- Driver.Infrastructure
- Driver.Contracts
- Driver.Core

#### 3. Folder Structure

```text
Driver.sln
src/
  Driver.API/
  Driver.Application/
    Assignments/
    Routes/
    Location/
  Driver.Domain/
    Entities/
    Aggregates/
  Driver.Infrastructure/
    Persistence/
    Geolocation/
    Messaging/
  Driver.Contracts/
  Driver.Core/
```

#### 4. Dependency Diagram

```text
Driver.API -> Driver.Application -> Driver.Domain -> Driver.Core
Driver.API -> Driver.Contracts
Driver.Infrastructure -> Driver.Domain / Driver.Application / Driver.Contracts
```

#### 5. Allowed Project References

- Driver.API -> Driver.Application, Driver.Contracts, Driver.Core, SharedKernel.Contracts
- Driver.Application -> Driver.Domain, Driver.Contracts, Driver.Core, SharedKernel.Contracts
- Driver.Domain -> Driver.Core, SharedKernel.Contracts
- Driver.Infrastructure -> Driver.Domain, Driver.Application, Driver.Contracts, Driver.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- Driver.API must not reference Mobile.API or ERP.API directly.
- Driver.Infrastructure must not depend on ERP persistence implementations.

#### 7. Authentication Boundary

- Driver owns its own authentication and session model for field staff.
- Device and driver identity are isolated from ERP employees.

#### 8. Database Boundary

- Driver owns its own database.
- Core tables include Driver, DriverLocation, DriverRoute, DriverAssignment, DriverStatusEvent.

#### 9. API Boundary

- Base route: /api/v1/driver/
- Examples: /api/v1/driver/location, /api/v1/driver/assignments

#### 10. Configuration Strategy

- Driver-specific settings for geolocation, push notifications, and route optimization.

#### 11. Logging Strategy

- Structured logs for route milestones, status updates, and GPS events.

#### 12. Caching Strategy

- Cache active assignment data and route state for low-latency driver operations.

#### 13. Background Job Strategy

- Queue-based workers for task dispatch, route recomputation, and status event propagation.

#### 14. Deployment Strategy

- Independent deployment behind driver.floraprise.com or a dedicated mobile app backend.

#### 15. Versioning Strategy

- Versioned route payloads and driver event contracts.

#### 16. Testing Strategy

- Unit tests for route rules and assignment logic.
- Integration tests for geolocation event ingestion.

#### 17. Future Scaling Strategy

- Separate scaling for location events and assignment processing.

---

### Customer

#### 1. Visual Studio Solution Structure

- Solution: Customer.sln
- Product boundary: customer-facing tracking, notifications, and customer self-service experiences.

#### 2. Projects

- Customer.API
- Customer.Application
- Customer.Domain
- Customer.Infrastructure
- Customer.Contracts
- Customer.Core

#### 3. Folder Structure

```text
Customer.sln
src/
  Customer.API/
  Customer.Application/
    Profiles/
    Tracking/
    Notifications/
  Customer.Domain/
  Customer.Infrastructure/
  Customer.Contracts/
  Customer.Core/
```

#### 4. Dependency Diagram

```text
Customer.API -> Customer.Application -> Customer.Domain -> Customer.Core
Customer.API -> Customer.Contracts
Customer.Infrastructure -> Customer.Domain / Customer.Application / Customer.Contracts
```

#### 5. Allowed Project References

- Customer.API -> Customer.Application, Customer.Contracts, Customer.Core, SharedKernel.Contracts
- Customer.Application -> Customer.Domain, Customer.Contracts, Customer.Core, SharedKernel.Contracts
- Customer.Domain -> Customer.Core, SharedKernel.Contracts
- Customer.Infrastructure -> Customer.Domain, Customer.Application, Customer.Contracts, Customer.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- Customer.API must not depend on ERP.API or Mobile.API internals.

#### 7. Authentication Boundary

- Customer owns its own customer identity and self-service authentication.

#### 8. Database Boundary

- Customer owns its own database.
- Core tables include CustomerProfile, CustomerTrackingEvent, CustomerNotification, CustomerPreference.

#### 9. API Boundary

- Base route: /api/v1/customer/
- Examples: /api/v1/customer/track, /api/v1/customer/notifications

#### 10. Configuration Strategy

- Product-specific settings for notifications, tracking, and customer preferences.

#### 11. Logging Strategy

- Structured logs for customer events and notification outcomes.

#### 12. Caching Strategy

- Cache recent customer activity and notification states.

#### 13. Background Job Strategy

- Queue-based workers for event processing and notification dispatch.

#### 14. Deployment Strategy

- Independent deployment behind customer.floraprise.com.

#### 15. Versioning Strategy

- Version customer APIs and notification payloads independently.

#### 16. Testing Strategy

- Unit tests for tracking logic and notification rules.
- Integration tests for customer event ingestion.

#### 17. Future Scaling Strategy

- Scale independently based on customer traffic and tracking event volume.

---

### Relay

#### 1. Visual Studio Solution Structure

- Solution: Relay.sln
- Product boundary: relay coordination, routing, message handoff, and integration operations.

#### 2. Projects

- Relay.API
- Relay.Application
- Relay.Domain
- Relay.Infrastructure
- Relay.Contracts
- Relay.Core

#### 3. Folder Structure

```text
Relay.sln
src/
  Relay.API/
  Relay.Application/
    Handoffs/
    Routes/
  Relay.Domain/
  Relay.Infrastructure/
    Messaging/
    Queues/
  Relay.Contracts/
  Relay.Core/
```

#### 4. Dependency Diagram

```text
Relay.API -> Relay.Application -> Relay.Domain -> Relay.Core
Relay.API -> Relay.Contracts
Relay.Infrastructure -> Relay.Domain / Relay.Application / Relay.Contracts
```

#### 5. Allowed Project References

- Relay.API -> Relay.Application, Relay.Contracts, Relay.Core, SharedKernel.Contracts
- Relay.Application -> Relay.Domain, Relay.Contracts, Relay.Core, SharedKernel.Contracts
- Relay.Domain -> Relay.Core, SharedKernel.Contracts
- Relay.Infrastructure -> Relay.Domain, Relay.Application, Relay.Contracts, Relay.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- Relay must not directly depend on ERP or Mobile runtime services.

#### 7. Authentication Boundary

- Relay uses service-to-service authentication and internal trust boundaries.

#### 8. Database Boundary

- Relay owns its own database.
- Core tables include RelayNode, RelayPackage, RelayRoute, RelayMessage.

#### 9. API Boundary

- Base route: /api/v1/relay/
- Examples: /api/v1/relay/handoffs, /api/v1/relay/routes

#### 10. Configuration Strategy

- Dedicated settings for queue endpoints, routing rules, and integration policies.

#### 11. Logging Strategy

- Structured logs for handoff events and failed message workflows.

#### 12. Caching Strategy

- Cache route state and active relay messaging metadata.

#### 13. Background Job Strategy

- Queue-based background workers for retransmission and relay orchestration.

#### 14. Deployment Strategy

- Independent deployment behind relay.floraprise.com.

#### 15. Versioning Strategy

- Version relay contracts and routing payloads independently.

#### 16. Testing Strategy

- Unit tests for routing rules.
- Integration tests for message handoff workflows.

#### 17. Future Scaling Strategy

- Scale independently for high-throughput relay operations.

---

### Website

#### 1. Visual Studio Solution Structure

- Solution: Website.sln
- Product boundary: public website and marketing experience, with a BFF API layer if needed.

#### 2. Projects

- Website.API
- Website.Application
- Website.Domain
- Website.Infrastructure
- Website.Contracts
- Website.Core

#### 3. Folder Structure

```text
Website.sln
src/
  Website.API/
  Website.Application/
    Content/
    Leads/
  Website.Domain/
  Website.Infrastructure/
  Website.Contracts/
  Website.Core/
```

#### 4. Dependency Diagram

```text
Website.API -> Website.Application -> Website.Domain -> Website.Core
Website.API -> Website.Contracts
Website.Infrastructure -> Website.Domain / Website.Application / Website.Contracts
```

#### 5. Allowed Project References

- Website.API -> Website.Application, Website.Contracts, Website.Core, SharedKernel.Contracts
- Website.Application -> Website.Domain, Website.Contracts, Website.Core, SharedKernel.Contracts
- Website.Domain -> Website.Core, SharedKernel.Contracts
- Website.Infrastructure -> Website.Domain, Website.Application, Website.Contracts, Website.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- Website.API must not depend on ERP or Mobile application services directly.

#### 7. Authentication Boundary

- Website owns public and customer-facing web authentication, with optional anonymous access.

#### 8. Database Boundary

- Website owns its own database.
- Core tables include WebsitePageView, WebsiteLead, WebsiteContent, WebsiteSession.

#### 9. API Boundary

- Base route: /api/v1/website/
- Examples: /api/v1/website/leads, /api/v1/website/content

#### 10. Configuration Strategy

- Public web settings, content flags, and SEO metadata stored independently.

#### 11. Logging Strategy

- Structured logs for page and form activity, with privacy-safe audit data.

#### 12. Caching Strategy

- Cache content pages and navigation structures aggressively.

#### 13. Background Job Strategy

- Queue-based jobs for lead processing and content publishing workflows.

#### 14. Deployment Strategy

- Independent deployment on a public web host.
- Recommended: floraprise.com and www.floraprise.com

#### 15. Versioning Strategy

- Version website APIs and public content contract separately.

#### 16. Testing Strategy

- Unit tests for content and lead workflows.
- E2E tests for public user journeys.

#### 17. Future Scaling Strategy

- Scale content delivery independently from transactional systems.

---

### Analytics

#### 1. Visual Studio Solution Structure

- Solution: Analytics.sln
- Product boundary: reporting, analytics pipelines, metrics, and business intelligence.

#### 2. Projects

- Analytics.API
- Analytics.Application
- Analytics.Domain
- Analytics.Infrastructure
- Analytics.Contracts
- Analytics.Core

#### 3. Folder Structure

```text
Analytics.sln
src/
  Analytics.API/
  Analytics.Application/
    Reports/
    Pipelines/
  Analytics.Domain/
  Analytics.Infrastructure/
    Storage/
    ETL/
  Analytics.Contracts/
  Analytics.Core/
```

#### 4. Dependency Diagram

```text
Analytics.API -> Analytics.Application -> Analytics.Domain -> Analytics.Core
Analytics.API -> Analytics.Contracts
Analytics.Infrastructure -> Analytics.Domain / Analytics.Application / Analytics.Contracts
```

#### 5. Allowed Project References

- Analytics.API -> Analytics.Application, Analytics.Contracts, Analytics.Core, SharedKernel.Contracts
- Analytics.Application -> Analytics.Domain, Analytics.Contracts, Analytics.Core, SharedKernel.Contracts
- Analytics.Domain -> Analytics.Core, SharedKernel.Contracts
- Analytics.Infrastructure -> Analytics.Domain, Analytics.Application, Analytics.Contracts, Analytics.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- Analytics must not depend on ERP or Mobile persistence models directly.

#### 7. Authentication Boundary

- Analytics uses internal service authentication and role-based access for reporting users.

#### 8. Database Boundary

- Analytics owns its own storage and reporting dataset.
- Core tables include AnalyticsEvent, ReportDefinition, MetricsSnapshot, DashboardDefinition.

#### 9. API Boundary

- Base route: /api/v1/analytics/
- Examples: /api/v1/analytics/reports, /api/v1/analytics/dashboards

#### 10. Configuration Strategy

- Separate settings for data pipelines, warehouse connections, and reporting caches.

#### 11. Logging Strategy

- Structured logs for pipeline execution, report generation, and processing failures.

#### 12. Caching Strategy

- Cache frequently requested dashboards and aggregated metrics.

#### 13. Background Job Strategy

- Queue-based workers for ETL, aggregation, and report generation.

#### 14. Deployment Strategy

- Independent deployment behind analytics.floraprise.com.

#### 15. Versioning Strategy

- Version report contracts and analytics event schemas independently.

#### 16. Testing Strategy

- Unit tests for aggregation logic.
- Integration tests for ETL and reporting pipelines.

#### 17. Future Scaling Strategy

- Scale read-heavy analytics services separately from transactional products.

---

### Admin Portal

#### 1. Visual Studio Solution Structure

- Solution: AdminPortal.sln
- Product boundary: internal administration console for platform operators and support staff.

#### 2. Projects

- AdminPortal.API
- AdminPortal.Application
- AdminPortal.Domain
- AdminPortal.Infrastructure
- AdminPortal.Contracts
- AdminPortal.Core

#### 3. Folder Structure

```text
AdminPortal.sln
src/
  AdminPortal.API/
  AdminPortal.Application/
    Users/
    Permissions/
    Audit/
  AdminPortal.Domain/
  AdminPortal.Infrastructure/
  AdminPortal.Contracts/
  AdminPortal.Core/
```

#### 4. Dependency Diagram

```text
AdminPortal.API -> AdminPortal.Application -> AdminPortal.Domain -> AdminPortal.Core
AdminPortal.API -> AdminPortal.Contracts
AdminPortal.Infrastructure -> AdminPortal.Domain / AdminPortal.Application / AdminPortal.Contracts
```

#### 5. Allowed Project References

- AdminPortal.API -> AdminPortal.Application, AdminPortal.Contracts, AdminPortal.Core, SharedKernel.Contracts
- AdminPortal.Application -> AdminPortal.Domain, AdminPortal.Contracts, AdminPortal.Core, SharedKernel.Contracts
- AdminPortal.Domain -> AdminPortal.Core, SharedKernel.Contracts
- AdminPortal.Infrastructure -> AdminPortal.Domain, AdminPortal.Application, AdminPortal.Contracts, AdminPortal.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- AdminPortal must not use another product’s runtime services directly.

#### 7. Authentication Boundary

- AdminPortal owns its own admin identity and permission model.

#### 8. Database Boundary

- AdminPortal owns its own database.
- Core tables include AdminUser, Permission, AuditLog, PlatformSetting.

#### 9. API Boundary

- Base route: /api/v1/admin/
- Examples: /api/v1/admin/users, /api/v1/admin/audit

#### 10. Configuration Strategy

- Separate settings for access control, support tools, and operational flags.

#### 11. Logging Strategy

- Audit-friendly logs for admin actions and support cases.

#### 12. Caching Strategy

- Cache permission grants and role maps for fast admin operations.

#### 13. Background Job Strategy

- Queue-based jobs for audit exports and support workflows.

#### 14. Deployment Strategy

- Independent deployment behind admin.floraprise.com.

#### 15. Versioning Strategy

- Version admin APIs and permission schemas independently.

#### 16. Testing Strategy

- Unit tests for permissions and action policies.
- Integration tests for audit workflows.

#### 17. Future Scaling Strategy

- Scale independently as support and platform administration mature.

---

### API Gateway

#### 1. Visual Studio Solution Structure

- Solution: ApiGateway.sln
- Product boundary: ingress, routing, authentication policy, throttling, and API composition.

#### 2. Projects

- ApiGateway.API
- ApiGateway.Application
- ApiGateway.Domain
- ApiGateway.Infrastructure
- ApiGateway.Contracts
- ApiGateway.Core

#### 3. Folder Structure

```text
ApiGateway.sln
src/
  ApiGateway.API/
    Routing/
    Middleware/
  ApiGateway.Application/
    Policies/
    Routing/
  ApiGateway.Domain/
    Rules/
    Models/
  ApiGateway.Infrastructure/
    ReverseProxy/
    AuthProviders/
  ApiGateway.Contracts/
  ApiGateway.Core/
```

#### 4. Dependency Diagram

```text
ApiGateway.API -> ApiGateway.Application -> ApiGateway.Domain -> ApiGateway.Core
ApiGateway.API -> ApiGateway.Contracts
ApiGateway.Infrastructure -> ApiGateway.Domain / ApiGateway.Application / ApiGateway.Contracts
```

#### 5. Allowed Project References

- ApiGateway.API -> ApiGateway.Application, ApiGateway.Contracts, ApiGateway.Core, SharedKernel.Contracts
- ApiGateway.Application -> ApiGateway.Domain, ApiGateway.Contracts, ApiGateway.Core, SharedKernel.Contracts
- ApiGateway.Domain -> ApiGateway.Core, SharedKernel.Contracts
- ApiGateway.Infrastructure -> ApiGateway.Domain, ApiGateway.Application, ApiGateway.Contracts, ApiGateway.Core, SharedKernel.Contracts

#### 6. Forbidden Project References

- ApiGateway must not depend on ERP or Mobile application internals.
- ApiGateway should not own business logic for product domains.

#### 7. Authentication Boundary

- API Gateway owns entry-level authentication, policy evaluation, and token validation.
- Gateway should not replace each product’s own domain authentication rules.

#### 8. Database Boundary

- API Gateway owns its own configuration database only if required.
- Gateway should not own transactional business data.

#### 9. API Boundary

- Base route: /gateway/
- Examples: /gateway/erp, /gateway/mobile, /gateway/driver

#### 10. Configuration Strategy

- Central route definitions, rate limiting policies, and auth policy rules.
- Route configuration is separate from product config.

#### 11. Logging Strategy

- Request and response correlation logs, policy decision logs, and latency metrics.

#### 12. Caching Strategy

- Cache route tables and policy decisions, not business data.

#### 13. Background Job Strategy

- Background jobs for topology refresh and policy cache invalidation.

#### 14. Deployment Strategy

- Independent deployment behind api.floraprise.com.

#### 15. Versioning Strategy

- Gateway routes are versioned separately from downstream product APIs.

#### 16. Testing Strategy

- Unit tests for route and policy logic.
- Integration tests for gateway-to-product routing and authentication flow.

#### 17. Future Scaling Strategy

- Gateway scales independently to absorb traffic spikes and support multi-region deployment.

---

## 6. Database Ownership Matrix

| Domain Object | Owner |
|---|---|
| Company | ERP |
| Account | ERP |
| LedgerEntry | ERP |
| Order | ERP |
| InventoryItem | ERP |
| Employee | ERP |
| TaxRule | ERP |
| MobileUser | Mobile |
| MobileDevice | Mobile |
| MobileSession | Mobile |
| MobileSubscription | Mobile |
| MobileOrderDraft | Mobile |
| Driver | Driver |
| DriverLocation | Driver |
| DriverAssignment | Driver |
| DriverRoute | Driver |
| CustomerProfile | Customer |
| CustomerTrackingEvent | Customer |
| CustomerNotification | Customer |
| RelayNode | Relay |
| RelayPackage | Relay |
| RelayRoute | Relay |
| WebsiteLead | Website |
| WebsiteContent | Website |
| WebsitePageView | Website |
| AnalyticsEvent | Analytics |
| MetricsSnapshot | Analytics |
| ReportDefinition | Analytics |
| AdminUser | Admin Portal |
| AuditLog | Admin Portal |
| PlatformSetting | Admin Portal |
| GatewayRouteConfig | API Gateway |
| GatewayPolicy | API Gateway |

---

## 7. API Ownership Matrix

| API Route | Owner |
|---|---|
| POST /api/v1/erp/orders | ERP |
| GET /api/v1/erp/inventory | ERP |
| POST /api/v1/mobile/auth/login | Mobile |
| POST /api/v1/mobile/subscriptions | Mobile |
| POST /api/v1/driver/location | Driver |
| POST /api/v1/driver/assignments | Driver |
| POST /api/v1/customer/track | Customer |
| POST /api/v1/customer/notifications | Customer |
| POST /api/v1/relay/handoffs | Relay |
| GET /api/v1/website/content | Website |
| GET /api/v1/analytics/reports | Analytics |
| GET /api/v1/admin/users | Admin Portal |
| GET /gateway/erp/* | API Gateway |

---

## 8. Deployment Topology

| Product | Recommended Hostname | Deployment Shape |
|---|---|---|
| ERP | erp.floraprise.com | Independent application deployment |
| Mobile | mobile.floraprise.com | Independent API deployment |
| Driver | driver.floraprise.com | Independent API deployment |
| Customer | customer.floraprise.com | Independent API deployment |
| Relay | relay.floraprise.com | Independent API deployment |
| Website | floraprise.com / www.floraprise.com | Public web deployment |
| Analytics | analytics.floraprise.com | Independent analytics deployment |
| Admin Portal | admin.floraprise.com | Independent admin deployment |
| API Gateway | api.floraprise.com | Front-door routing layer |

---

## 9. Recommended Operating Model

- Each product has its own release train.
- Each product has its own CI/CD pipeline.
- Each product has its own observability stack.
- Each product has its own secrets and environment configuration.
- Cross-product changes are approved through the governance model and are implemented only through documented contracts.

---

## 10. Final Decision

The correct enterprise structure for Floraprise is a product-oriented, independently deployable platform with strong boundaries around auth, data, and APIs. ERP remains the core operational platform, while Mobile, Driver, Customer, Relay, Website, Analytics, Admin Portal, and API Gateway are separate products that evolve independently.
