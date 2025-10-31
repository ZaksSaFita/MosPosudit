# Konfiguracija aplikacije

## Pregled

Aplikacija koristi dva različita načina konfiguracije:

1. **`.env` fajl** - za Docker deployment
2. **`appsettings.json`** - za lokalni development bez Docker-a

## Docker Deployment (`.env`)

Kada koristiš Docker sa `docker-compose up`:

- Sve konfiguracije se čitaju iz **`.env`** fajla
- `docker-compose.yml` automatski učitava varijable iz `.env`
- `appsettings.json` fajlovi se **ignorišu** jer Docker prosleđuje environment varijable direktno

**Kako koristiti:**
1. Kopiraj `.env.example` u `.env`
2. Ažuriraj vrijednosti u `.env`
3. Pokreni `docker-compose up`

## Lokalni Development (`appsettings.json`)

Kada radiš lokalno bez Docker-a (npr. `dotnet run`):

- Koristi se **`appsettings.json`** za osnovne postavke
- **`appsettings.Development.json`** nadjačava postavke kada je `ASPNETCORE_ENVIRONMENT=Development`
- `.env` fajl se **ne koristi** u lokalnom developmentu

**Kako koristiti:**
1. Ažuriraj `MosPosudit.WebAPI/appsettings.json`
2. Ažuriraj `MosPosudit.Worker/appsettings.json`
3. Pokreni `dotnet run` u odgovarajućem projektu

## Koji fajl mijenjati?

| Scenario | Fajl za mijenjanje |
|----------|-------------------|
| Docker deployment | `.env` |
| Lokalno bez Docker-a | `appsettings.json` i `appsettings.Development.json` |

## Struktura konfiguracija

### Docker (.env)
```
SQL_SERVER_PASSWORD=...
DATABASE_NAME=220116
RABBITMQ_USERNAME=admin
RABBITMQ_PASSWORD=admin123
DB_CONNECTION_STRING=...
JWT_KEY=...
JWT_ISSUER=...
JWT_AUDIENCE=...
PAYPAL_CLIENT_ID=...
SMTP_USERNAME=...
...
```

### Lokalno (appsettings.json)
```json
{
  "ConnectionStrings": { "DefaultConnection": "..." },
  "RabbitMQ": { "Host": "localhost", ... },
  "Jwt": { "Key": "...", "Issuer": "...", "Audience": "..." },
  "PayPal": { "ClientId": "...", ... },
  "SMTP": { "Host": "...", ... }
}
```

## Važno

- **`.env`** se NE commit-uje u git (u `.gitignore`)
- **`appsettings.json`** se commit-uje u git
- **`.env.example`** se commit-uje kao template

