# Sumpooj API

ASP.NET Core Web API for the Floraprise ERP system.

## Sprint 1.5 Implementation

### Features Implemented

#### 1. Global Exception Handling
- Centralized exception handling middleware in `Program.cs`
- Returns standardized `ProblemDetails` responses for all unhandled exceptions
- Includes correlation ID for request tracing
- Logs all exceptions with structured logging

#### 2. Standardized API Responses
- `ApiResponse<T>` wrapper class in `Models/ApiResponse.cs`
- Consistent response structure across all endpoints:
  ```json
  {
    "success": true,
    "data": { ... },
    "message": null,
    "errorCode": null,
    "correlationId": "guid",
    "timestampUtc": "2026-07-31T00:00:00Z"
  }
  ```
- Static factory methods: `Ok()`, `Error()`

#### 3. API Versioning
- URL-based versioning using `Microsoft.AspNetCore.Mvc.Versioning`
- Default version: 1.0
- All mobile endpoints use `/api/v1/mobile/*` prefix
- Version reporting enabled in response headers

#### 4. Request Logging with Correlation IDs
- Automatic correlation ID generation for each request
- Logged in `X-Correlation-ID` response header
- Structured logging includes:
  - Correlation ID
  - Company ID (from JWT claims)
  - User ID (from JWT claims)
  - Device ID (from JWT claims)
  - Subscription ID (from JWT claims)
  - Endpoint path
  - Request duration
  - HTTP status code

#### 5. Health Endpoints
- `/health` - Combined health status
- `/health/live` - Liveness probe (always returns healthy if service is running)
- `/health/ready` - Readiness probe (checks database, migrations, JWT config, mobile services, subscription services, device services)

#### 6. Folder Structure
```
Sumpooj.API/
├── Authorization/          # Authorization policies and handlers
├── Controllers/            # API controllers
│   └── Mobile/            # Mobile-specific controllers
├── Hubs/                   # SignalR hubs
├── Infrastructure/         # Infrastructure components
│   ├── Health/            # Health check implementations
│   └── OpenApi/           # OpenAPI/Swagger transformers
├── Middleware/             # Custom middleware
├── Models/                 # Shared models (ApiResponse, etc.)
├── Services/               # Application services
└── Program.cs             # Application startup and configuration
```

## Health Endpoints

### GET /health/live
Returns liveness status. Always returns 200 OK if the service is running.

**Response:**
```json
{
  "status": "Healthy",
  "totalDuration": "00:00:00.0012345",
  "entries": {
    "live": {
      "data": {},
      "description": "Service is alive.",
      "status": "Healthy",
      "duration": "00:00:00.0001234"
    }
  }
}
```

### GET /health/ready
Returns readiness status. Checks all dependencies.

**Response:**
```json
{
  "status": "Healthy",
  "totalDuration": "00:00:00.1234567",
  "entries": {
    "database": { "status": "Healthy", ... },
    "migrations": { "status": "Healthy", ... },
    "jwt": { "status": "Healthy", ... },
    "mobile_services": { "status": "Healthy", ... },
    "subscription_services": { "status": "Healthy", ... },
    "device_services": { "status": "Healthy", ... }
  }
}
```

## API Versioning

All endpoints are versioned using URL path versioning:

- **Version 1.0**: `/api/v1/*`
- **Mobile endpoints**: `/api/v1/mobile/*`

Example:
- `POST /api/v1/mobile/auth/register`
- `GET /api/v1/mobile/delivery/workspace/active`

## Correlation IDs

Every request automatically receives a correlation ID:
- Generated as a GUID
- Returned in `X-Correlation-ID` response header
- Included in all log entries for that request
- Useful for tracing requests across distributed systems

## Running the Application

### Development
```bash
cd Sumpooj.API
dotnet run
```

### Production
```bash
cd Sumpooj.API
dotnet publish -c Release
./bin/Release/net10.0/publish/Sumpooj.API
```

### Docker
```bash
docker-compose up
```

## Configuration

Key configuration in `appsettings.json`:
- `ConnectionStrings:Default` - PostgreSQL connection string
- `Jwt:Key` - JWT signing key
- `Jwt:Issuer` - JWT issuer
- `Cors:AllowedOrigins` - CORS allowed origins array

## OpenAPI Documentation

Scalar API documentation available at `/scalar/v1` when running in development mode.

## Dependencies

- .NET 10.0
- PostgreSQL
- ASP.NET Core JWT Bearer Authentication
- Entity Framework Core
- Scalar.AspNetCore (API documentation)
