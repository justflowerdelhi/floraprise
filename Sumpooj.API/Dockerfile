# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["Sumpooj.API.csproj", "./"]
RUN dotnet restore "Sumpooj.API.csproj"

# Copy everything else and build
COPY . .
RUN dotnet publish "Sumpooj.API.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Expose port
EXPOSE 8080
EXPOSE 8443

# Copy published app
COPY --from=build /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Sumpooj.API.dll"]
