# Base image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000
EXPOSE 5001
ENV ASPNETCORE_URLS=http://+:5000

# Build image
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .

# Publish
FROM build AS publish
RUN dotnet publish "MošPosudit.WebAPI/MošPosudit.WebAPI.csproj" -c Release -o /app

# Final image
FROM base AS final
WORKDIR /app
COPY --from=publish /app .

ENTRYPOINT ["dotnet", "MošPosudit.WebAPI.dll"] 