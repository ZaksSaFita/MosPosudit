# MosPosudit - Tool Rental System

A microservices-based tool rental application built with .NET Core, Flutter, and Docker.

## 🏗️ Architecture

- **Backend**: .NET Core 8.0 (C#) with microservices architecture
- **Frontend**: Flutter (Desktop + Mobile)
- **Database**: SQL Server 2022
- **Message Queue**: RabbitMQ
- **Containerization**: Docker + docker-compose

## 🐳 Quick Start with Docker

### Prerequisites
- Docker Desktop
- Docker Compose

### 1. Clone the repository
```bash
git clone <repository-url>
cd MosPosudit
```

### 2. Configure environment variables

Copy `.env.example` to `.env` and update the configuration:

```bash
cp .env.example .env
```

**Edit `.env` file with your configuration:**

- **Database**: Update `SQL_SERVER_PASSWORD` and `DATABASE_NAME` if needed
- **RabbitMQ**: Update `RABBITMQ_USERNAME` and `RABBITMQ_PASSWORD` if needed
- **JWT**: Update `JWT_KEY` (must be at least 32 characters)
- **PayPal**: Update `PAYPAL_CLIENT_ID` and `PAYPAL_SECRET` with your PayPal credentials
- **SMTP**: Update `SMTP_USERNAME` and `SMTP_PASSWORD` with your email credentials
  - For Gmail, you'll need to generate an App Password
- **API**: Update `API_PORT` if needed (default: 5001)

**For Mobile App**: 
- When running on physical device, use `--dart-define=API_URL=http://YOUR_IP:5001/api`
- For Android emulator, default `10.0.2.2` is used automatically
- To find your IP address, run `ipconfig` in Command Prompt and look for "IPv4 Address"

### 3. Start all services
```bash
docker-compose up -d
```

This will start:
- SQL Server (port 1433)
- RabbitMQ (ports 5672, 15672)
- API Service (ports 5001, 5002)
- Worker Service (background processing)

**Note**: First run may take 5-10 minutes to download images and build containers.

### 4. Check service status
```bash
docker-compose ps
docker-compose logs api
docker-compose logs worker
```

### 5. Access the application

- **API Documentation**: http://localhost:5001/swagger
- **RabbitMQ Management**: http://localhost:15672 (admin/admin123)
- **Desktop App**: Run `flutter run -d windows` in `MosPosudit.UI/desktop`
- **Mobile App**: Run `flutter run` in `MosPosudit.UI/mobile`

### 6. Stop services
```bash
docker-compose down
```

To remove all data (volumes):
```bash
docker-compose down -v
```

## 🔐 Login Credentials

### Desktop Application
- **Username**: `desktop`
- **Password**: `test`

### Mobile Application
- **Username**: `mobile`
- **Password**: `test`

### Additional Roles (if created)
- **Username**: `{roleName}`
- **Password**: `test`

## 📁 Project Structure

```
MosPosudit/
├── MosPosudit.Model/          # Data models and DTOs
├── MosPosudit.Services/       # Business logic and data access
├── MosPosudit.WebAPI/         # Main REST API service
├── MosPosudit.Worker/         # Background worker service
├── MosPosudit.UI/
│   ├── desktop/              # Flutter desktop application
│   └── mobile/               # Flutter mobile application
├── docker-compose.yml        # Docker orchestration
└── README.md
```

## 🔧 Services

### API Service (Port 5001/5002)
- REST API endpoints
- JWT authentication
- User management
- Tool rental operations

### Worker Service
- Background task processing
- Email notifications
- Rental reminders
- System notifications

### RabbitMQ
- Message queue for inter-service communication
- Queues: notifications, emails, rental_reminders

## 🗄️ Database

- **Database Name**: 180081
- **Tables**: 10+ functional tables (Users, Tools, Rentals, etc.)
- **Seeding**: Test data included

## 🚀 Development

### Quick Start with Docker (Recommended)
```bash
# 1. Update mobile IP address in constants.dart
# 2. Start all services
docker-compose up -d

# 3. Check services are running
docker-compose ps

# 4. Run Flutter apps
cd MosPosudit.UI/desktop && flutter run -d windows
cd MosPosudit.UI/mobile && flutter run
```

### Running Locally (without Docker)

**Prerequisites**:
- .NET 8.0 SDK
- SQL Server 2022 Express
- RabbitMQ Server
- Flutter SDK

**Setup**:

1. **Database**: Start SQL Server locally
   - Install SQL Server 2022 Express
   - Create database named `180081`
   - Update connection string in `appsettings.json`

2. **RabbitMQ**: Install and start RabbitMQ locally
   - Download from https://www.rabbitmq.com/download.html
   - Start RabbitMQ service
   - Access management UI at http://localhost:15672 (guest/guest)

3. **API**: Run `dotnet run` in `MosPosudit.WebAPI`
   - API will be available at http://localhost:5001

4. **Worker**: Run `dotnet run` in `MosPosudit.Worker`
   - Worker will process background tasks

**Note**: For mobile development on physical devices, use `--dart-define=API_URL=http://YOUR_IP:5001/api` when running Flutter. For emulator, default `10.0.2.2` is used automatically.

### Flutter Development

```bash
# Desktop
cd MosPosudit.UI/desktop
flutter pub get
flutter run -d windows --dart-define=API_URL=http://localhost:5001/api

# Mobile (Android Emulator - 10.0.2.2 maps to host's localhost)
cd MosPosudit.UI/mobile
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:5001/api

# Mobile (Physical Device - replace YOUR_IP with your computer's IP)
flutter run --dart-define=API_URL=http://YOUR_IP:5001/api
```

**Note**: API URL can be configured via `--dart-define` parameter. Default values are set in `constants.dart` files.

## 📋 Features

- ✅ User authentication and authorization
- ✅ Tool management and rental system
- ✅ Real-time notifications
- ✅ Email notifications
- ✅ Microservices architecture
- ✅ Docker containerization
- ✅ RabbitMQ message queuing
- ✅ Cross-platform Flutter applications

## 🔍 Troubleshooting

### Quick Fix for Mobile Connection
If you're getting "check your internet connection" error on mobile:

1. **Find your computer's IP**:
   ```bash
   ipconfig
   ```
   Look for "IPv4 Address" (e.g., 192.168.1.100)

2. **Update mobile app**:
   - Open `MosPosudit.UI/mobile/lib/core/constants.dart`
   - Change `192.168.1.100` to your actual IP address

3. **Test connection**:
   - Open mobile browser
   - Go to `http://YOUR_IP:5001/swagger`
   - If it loads, the connection works

4. **Alternative solutions**:
   - Use `10.0.2.2` for Android emulator
   - Use `localhost` for iOS simulator
   - Use Docker with port forwarding

### Mobile Connection Issues
1. **Find your computer's IP address**:
   - Open Command Prompt and run `ipconfig`
   - Look for "IPv4 Address" under your network adapter
   - Update `MosPosudit.UI/mobile/lib/core/constants.dart` with this IP

2. **Check API service**:
   - Ensure API is running on port 5001
   - Test with: `curl http://localhost:5001/api/User/me`

3. **Network connectivity**:
   - Ensure mobile device and computer are on same network
   - Check Windows Firewall allows connections on port 5001
   - Try accessing API from mobile browser: `http://YOUR_IP:5001/swagger`

4. **Alternative solution**:
   - Use `10.0.2.2` for Android emulator
   - Use `localhost` for iOS simulator
   - Use Docker with port forwarding

### Docker Issues
1. Ensure Docker Desktop is running
2. Check if ports 5001, 1433, 5672, 15672 are available
3. Run `docker-compose logs` to check service status

### Database Issues
1. Wait for SQL Server to fully start (may take 30-60 seconds)
2. Check connection string in appsettings.json
3. Verify database name matches your index number

## 📝 Notes

- All configuration is externalized in `.env` file for Docker deployment
- For local development without Docker, use `appsettings.json` files
- `.env` file is in `.gitignore` - copy `.env.example` and configure your values
- No hardcoded values in the application
- Follows microservices best practices
- Implements proper error handling and validation
- Uses English language for all user-facing text
- Mobile app requires your computer's IP address for network connectivity
- Docker setup provides complete isolation and easy deployment
- RabbitMQ enables reliable message queuing between services

## 🔒 Environment Variables

All sensitive configuration is stored in `.env` file (not committed to git):
- Database credentials
- JWT secret key
- PayPal API credentials
- SMTP email credentials
- RabbitMQ credentials

Make sure to create `.env` from `.env.example` and update with your values before running `docker-compose up`. 