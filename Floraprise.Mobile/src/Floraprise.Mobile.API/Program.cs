using Floraprise.Mobile.Application;
using Floraprise.Mobile.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, _, _) =>
    {
        document.Info.Title = "Floraprise Mobile API";
        document.Info.Version = "v1";
        document.Info.Description = "Infrastructure foundation for future mobile features. JWT support is scaffolded via configuration and authentication placeholders.";
        document.Info.Contact = new Microsoft.OpenApi.OpenApiContact
        {
            Name = "Floraprise"
        };

        document.Components.Schemas["HealthResponse"] = new Microsoft.OpenApi.Models.OpenApiSchema
        {
            Type = "object",
            Properties = new Dictionary<string, Microsoft.OpenApi.Models.OpenApiSchema>
            {
                ["status"] = new Microsoft.OpenApi.Models.OpenApiSchema { Type = "string", Example = new Microsoft.OpenApi.Any.OpenApiString("ok") }
            }
        };

        return Task.CompletedTask;
    });
});
builder.Services.AddMobileApplication();
builder.Services.AddMobileInfrastructure(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.MapGet("/swagger", () => Results.Redirect("/openapi/v1.json"));

app.Run();
