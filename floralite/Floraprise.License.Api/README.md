# Floraprise License API

ASP.NET Core Web API for Floraprise cloud licensing.

## Run locally

1. Install .NET 10 SDK and PostgreSQL.
2. Set `ConnectionStrings__LicenseDatabase` or edit `appsettings.Development.json`.
3. Apply migrations:

```powershell
dotnet ef database update --project Floraprise.License.Api
```

4. Run the API:

```powershell
dotnet run --project Floraprise.License.Api
```

Point Flutter at the API with:

```powershell
flutter run --dart-define=FLORAPRISE_LICENSE_API_URL=https://your-license-api-host
```