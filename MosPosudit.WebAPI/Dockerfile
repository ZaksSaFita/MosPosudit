FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["MosPosudit.WebAPI/MosPosudit.WebAPI.csproj", "MosPosudit.WebAPI/"]
COPY ["MosPosudit.Services/MosPosudit.Services.csproj", "MosPosudit.Services/"]
COPY ["MosPosudit.Model/MosPosudit.Model.csproj", "MosPosudit.Model/"]
RUN dotnet restore "./MosPosudit.WebAPI/MosPosudit.WebAPI.csproj"
COPY . .
WORKDIR "/src/MosPosudit.WebAPI"
RUN dotnet build "./MosPosudit.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./MosPosudit.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MosPosudit.WebAPI.dll"]