# MosPosudit - Tool Rental System

A microservices-based tool rental application built with .NET Core, Flutter, and Docker.

## 🏗️ Architecture

- **Backend**: .NET Core 8.0 (C#) with microservices architecture
- **Frontend**: Flutter (Desktop + Mobile)
- **Database**: SQL Server 2022
- **Message Queue**: RabbitMQ
- **Containerization**: Docker + docker-compose

## 📋 Prerequisites

Before starting, ensure you have the following installed:

- **Docker Desktop** (must be running)
- **Flutter SDK** (latest version)
- **Git** (for cloning the repository)

## 🚀 Quick Start - Pokretanje aplikacije

### Korak 1: Kloniranje repozitorija

```bash
git clone <repository-url>
cd MosPosudit
```

### Korak 2: Konfiguracija okruženja

Kreirajte `.env` fajl u root direktoriju projekta sa sljedećim varijablama:

```env
# Database Configuration
SQL_SERVER_PASSWORD=YourStrongPassword123!
DATABASE_NAME=220116
DB_CONNECTION_STRING=Server=sqlserver;Database=220116;User Id=sa;Password=YourStrongPassword123!;TrustServerCertificate=True;MultipleActiveResultSets=true;

# RabbitMQ Configuration
RABBITMQ_USERNAME=admin
RABBITMQ_PASSWORD=admin123

# JWT Configuration
JWT_KEY=YourSuperSecretJWTKeyMustBeAtLeast32CharactersLong!
JWT_ISSUER=MosPosudit
JWT_AUDIENCE=MosPosuditUsers

# PayPal Configuration (Optional - for payment features)
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_SECRET=your_paypal_secret
PAYPAL_MODE=sandbox
PAYPAL_RETURN_URL=http://localhost:5001/api/Payment/paypal-return
PAYPAL_CANCEL_URL=http://localhost:5001/api/Payment/paypal-cancel

# SMTP Configuration (Optional - for email notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_ENABLE_SSL=true

# API Configuration
API_PORT=5001
API_ENVIRONMENT=Development
```

**Napomene:**
- `SQL_SERVER_PASSWORD` mora biti kompleksan (min. 8 karaktera, uključuje velika i mala slova, brojeve i specijalne znakove)
- `JWT_KEY` mora biti najmanje 32 karaktera dug
- `DB_CONNECTION_STRING` mora koristiti isti password kao `SQL_SERVER_PASSWORD`
- Za Gmail SMTP, koristite App Password (ne regularni password)

### Korak 3: Pokretanje servisa pomoću Docker Compose

U root direktoriju projekta, pokrenite:

```bash
docker-compose up -d
```

Ova komanda će pokrenuti:
- **SQL Server** na portu 1433
- **RabbitMQ** na portovima 5672 (AMQP) i 15672 (Management UI)
- **API Service** na portu 5001
- **Worker Service** (background processing)

**Napomena:** Prvo pokretanje može potrajati 5-10 minuta dok se slike preuzimaju i kontejneri grade.

### Korak 4: Provjera statusa servisa

Provjerite da li su svi servisi uspješno pokrenuti:

```bash
# Provjera statusa svih servisa
docker-compose ps

# Provjera logova API servisa
docker-compose logs api

# Provjera logova Worker servisa
docker-compose logs worker

# Provjera logova svih servisa
docker-compose logs -f
```

### Korak 5: Pokretanje Flutter aplikacija

#### Desktop aplikacija

```bash
cd MosPosudit.UI/desktop
flutter pub get
flutter run -d windows
```

Aplikacija će se pokrenuti na Windows platformi i automatski se povezati na API na `http://localhost:5001/api`.

#### Mobile aplikacija

**Za Android emulator (preporučeno):**

```bash
cd MosPosudit.UI/mobile
flutter pub get
flutter run
```

Android emulator automatski koristi `10.0.2.2` koji se mapira na hostov `localhost`.

**Za fizički uređaj:**

1. Pronađite IP adresu vašeg računara:
   ```bash
   ipconfig
   ```
   Potražite "IPv4 Address" (npr. `192.168.1.100`)

2. Pokrenite aplikaciju sa IP adresom:
   ```bash
   cd MosPosudit.UI/mobile
   flutter pub get
   flutter run --dart-define=API_URL=http://YOUR_IP:5001/api
   ```

**Za iOS simulator:**
```bash
cd MosPosudit.UI/mobile
flutter pub get
flutter run --dart-define=API_URL=http://localhost:5001/api
```

## 🔐 Login Credentials - Podaci za prijavu

### Desktop aplikacija
- **Username**: `desktop`
- **Password**: `test`

### Mobile aplikacija
- **Username**: `mobile`
- **Password**: `test`

### Dodatne uloge (ako postoje)
- **Username**: `{nazivUloge}`
- **Password**: `test`

## 🌐 Pristup servisima

Nakon pokretanja, dostupni su sljedeći servisi:

- **API Documentation (Swagger)**: http://localhost:5001/swagger
- **RabbitMQ Management UI**: http://localhost:15672
  - Username: `admin`
  - Password: `admin123` (ili vaša konfigurirana lozinka iz `.env`)

## 🛑 Zaustavljanje aplikacije

### Zaustavljanje svih servisa (čuvanje podataka)

```bash
docker-compose down
```

### Zaustavljanje i brisanje svih podataka

```bash
docker-compose down -v
```

**Upozorenje:** Ova komanda će obrisati sve podatke iz baze podataka i RabbitMQ!

## 🔧 Troubleshooting - Rešavanje problema

### Problem: Port je zauzet

Ako dobijete grešku da je port zauzet:

```bash
# Windows - provjeri ko koristi port
netstat -ano | findstr :5001

# Zaustavi kontejnere
docker-compose down

# Promijeni port u .env fajlu
API_PORT=5002
```

### Problem: Docker Desktop nije pokrenut

Uvjerite se da je Docker Desktop pokrenut i da se servisi mogu pokrenuti:

```bash
docker ps
```

Ako dobijete grešku, pokrenite Docker Desktop i sačekajte da se potpuno učita.

### Problem: Mobile aplikacija se ne može povezati na API

1. **Provjerite IP adresu:**
   ```bash
   ipconfig
   ```

2. **Provjerite da li API radi:**
   - Otvorite browser na mobilnom uređaju
   - Idite na: `http://YOUR_IP:5001/swagger`
   - Ako se stranica učitava, API radi

3. **Provjerite firewall:**
   - Windows Firewall mora dopustiti konekcije na portu 5001
   - Dodajte izuzetak u Windows Firewall za port 5001

4. **Za Android emulator:**
   - Koristite `10.0.2.2` umjesto IP adrese
   - Ili pokrenite: `flutter run` bez dodatnih parametara

### Problem: Baza podataka se ne kreira

Provjerite logove SQL Server kontejnera:

```bash
docker-compose logs sqlserver
```

Čekajte da SQL Server potpuno startuje (može potrajati 30-60 sekundi).

### Problem: Worker servis ne radi

Provjerite logove Worker servisa:

```bash
docker-compose logs worker -f
```

Uvjerite se da su RabbitMQ i API servisi pokrenuti i zdravi.

## 📁 Project Structure

```
MosPosudit/
├── MosPosudit.Model/          # Data models and DTOs
├── MosPosudit.Services/        # Business logic and data access
├── MosPosudit.WebAPI/          # Main REST API service
├── MosPosudit.Worker/          # Background worker service
├── MosPosudit.UI/
│   ├── desktop/               # Flutter desktop application
│   ├── mobile/                # Flutter mobile application
│   └── shared/                # Shared Flutter code
├── docker-compose.yml         # Docker orchestration
└── README.md
```

## 🔒 Security Notes

- **NE COMMIT-UJTE `.env` fajl** - sadrži osjetljive podatke
- `.env` fajl je već u `.gitignore`
- JWT key mora biti siguran i dugačak (min. 32 karaktera)
- Production okruženje zahtijeva dodatne sigurnosne mjere

## 📝 Additional Notes

- Svi konfiguracijski podaci su u `.env` fajlu (nikad hardkodirani u kodu)
- Baza podataka se automatski kreira i seed-uje pri prvom pokretanju
- RabbitMQ omogućava komunikaciju između API i Worker servisa
- Flutter aplikacije koriste `--dart-define` za konfiguraciju API URL-a
- Swagger dokumentacija dostupna na `/swagger` endpointu

## 🐳 Docker Services Overview

### SQL Server
- **Port**: 1433
- **Database**: 220116 (ili vaša konfigurirana vrijednost)
- **Username**: sa
- **Password**: iz `.env` fajla

### RabbitMQ
- **AMQP Port**: 5672
- **Management UI**: 15672
- **Credentials**: iz `.env` fajla

### API Service
- **Port**: 5001 (ili vaša konfigurirana vrijednost)
- **Swagger**: http://localhost:5001/swagger
- **Base URL**: http://localhost:5001/api

### Worker Service
- **Background processing**
- **Email notifications**
- **Rental reminders**
- **System notifications**

## ✅ Verifikacija instalacije

Nakon pokretanja, provjerite sljedeće:

1. ✅ Svi Docker kontejneri su pokrenuti (`docker-compose ps`)
2. ✅ API je dostupan na http://localhost:5001/swagger
3. ✅ RabbitMQ Management UI je dostupan na http://localhost:15672
4. ✅ Desktop aplikacija se pokreće bez grešaka
5. ✅ Mobile aplikacija se povezuje na API
6. ✅ Login funkcionalnost radi sa navedenim credentials

---

**Za dodatnu pomoć ili podršku, kontaktirajte tim za razvoj.**
