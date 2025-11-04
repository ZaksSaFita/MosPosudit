## ✅ Setup Instructions

### 1️⃣ Requirements

Make sure you have installed:

* Docker Desktop (running)
* Flutter SDK
* Git
* Android Emulator (for mobile testing)

---

### 2️⃣ Clone the repository

```bash
git clone <repository-url>
cd MosPosudit
```

---

### 3️⃣ Create/Unzip `.env` file

Place the `.env` file in the project root.
(If given in ZIP, unzip it to the main directory.)

---

### 4️⃣ Start Docker services

```bash
docker-compose up -d
```

Check containers:

```bash
docker-compose ps
```

**RabbitMQ Dashboard:**

* URL: `http://localhost:15672`
* Username: `admin`
* Password: `admin123` (or as in your `.env` file)

**API Swagger:**

* URL: `http://localhost:5001/swagger`

---

### 5️⃣ Install Flutter dependencies

```bash
cd MosPosudit.UI/shared
flutter pub get

cd ../mobile
flutter pub get

cd ../desktop
flutter pub get
```

---

### 6️⃣ Run the applications

#### Desktop

```bash
cd MosPosudit.UI/desktop
flutter run -d windows
```
After the desktop app starts, navigate to the ML Recommender System section and click Train Now to train the machine learning model for recommendations.
#### Mobile

Make sure the Android emulator is running:

```bash
cd MosPosudit.UI/mobile
flutter run
```

---

## 🔐 Login & Service Credentials

### Desktop App

* Username: `desktop`
* Password: `test`

### Mobile App

* Username: `mobile`
* Password: `test`

### RabbitMQ

* Username: `admin`
* Password: `admin123`

### PayPal (Sandbox / Dev)

* Email: `mosposudit3@gmail.com`
* Password: `Mosposudit123`

---
