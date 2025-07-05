FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MosPosudit.Worker/MosPosudit.Worker.csproj", "MosPosudit.Worker/"]
COPY ["MosPosudit.Services/MosPosudit.Services.csproj", "MosPosudit.Services/"]
COPY ["MosPosudit.Model/MosPosudit.Model.csproj", "MosPosudit.Model/"]
RUN dotnet restore "MosPosudit.Worker/MosPosudit.Worker.csproj"
COPY . .
WORKDIR "/src/MosPosudit.Worker"
RUN dotnet build "MosPosudit.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MosPosudit.Worker.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MosPosudit.Worker.dll"] 