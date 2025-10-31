# Project Architecture Rules - MosPosudit

## 📋 Osnovna Pravila Strukture Projekta

### 1. **Kreiranje Klase (Entity)**
Kada se kreira nova klasa/entitet u `MosPosudit.Services/DataBase/Data/`:
- ✅ Automatski se kreiraju:
  - **Request DTOs** u `MosPosudit.Model/Requests/[EntityName]/`
    - `[EntityName]InsertRequest.cs`
    - `[EntityName]UpdateRequest.cs`
    - `[EntityName]PatchRequest.cs` (opciono)
  - **Response DTOs** u `MosPosudit.Model/Responses/[EntityName]/`
    - `[EntityName]Response.cs`
  - **SearchObject** u `MosPosudit.Model/SearchObjects/`
    - `[EntityName]SearchObject.cs`

### 2. **Kreiranje Kontrolera**
Kada se kreira novi Controller u `MosPosudit.WebAPI/Controllers/`:
- ✅ Automatski se kreiraju:
  - **Service Interface** u `MosPosudit.Services/Interfaces/`
    - `I[EntityName]Service.cs`
  - **Service Implementation** u `MosPosudit.Services/Services/`
    - `[EntityName]Service.cs`
  - **Biznis logika ide u Service**, ne u Controller
  - Controller samo poziva Service metode i vraća HTTP odgovore

### 3. **Raspodjela Odgovornosti**

#### **Controller** (`MosPosudit.WebAPI/Controllers/`)
- Prima HTTP zahtjeve
- Validira input (DTOs)
- Poziva Service metode
- Vraća HTTP odgovore (200, 400, 404, 500)
- **NEMA** biznis logiku

#### **Service** (`MosPosudit.Services/Services/`)
- **Sve biznis logike** su ovdje
- Komunikacija sa bazom podataka (kroz DbContext)
- Validacija poslovnih pravila
- Transformacija podataka (Entity ↔ DTO)
- Poziva MessageService za notifikacije/emailove

#### **Interface** (`MosPosudit.Services/Interfaces/`)
- Definiše ugovor (contract) za Service
- Omogućava dependency injection i testiranje
- Implementiran od strane Service klase

### 4. **DTOs (Data Transfer Objects)**

#### **Request DTOs** (`MosPosudit.Model/Requests/`)
- Koriste se za unos podataka od klijenta
- Validacija atributa (`[Required]`, `[Email]`, itd.)
- Primeri: `LoginRequest`, `CategoryInsertRequest`, `UserUpdateRequest`

#### **Response DTOs** (`MosPosudit.Model/Responses/`)
- Koriste se za vraćanje podataka klijentu
- Ne sadrže osjetljive podatke (npr. password hash)
- Mogu kombinovati podatke iz više entiteta
- Primeri: `CategoryResponse`, `LoginResponse`, `ToolResponse`

#### **SearchObject** (`MosPosudit.Model/SearchObjects/`)
- Koristi se za filtriranje i pretragu
- Nasljeđuje `BaseSearchObject` (Pagination, Sorting, Filtering)
- Primeri: `CategorySearchObject`, `ToolSearchObject`, `UserSearchObject`

---

## 🔄 Worker Service - Objašnjenje

### **Šta je Worker Service?**

`MosPosudit.Worker` je **background service** (pozadinski servis) koji radi **nezavisno** od glavnog API servisa.

### **Zašto nam treba Worker?**

Worker omogućava **asinkronu obradu zadataka** koji:
1. **Ne trebaju biti odmah završeni** - korisnik ne mora čekati
2. **Mogu biti sporiji** - slanje emaila, kreiranje notifikacija
3. **Ne utiču na odgovor API-ja** - API brzo vraća odgovor

### **Kako funkcioniše?**

```
┌─────────────┐         ┌──────────┐         ┌─────────┐
│   WebAPI    │ ──────> │ RabbitMQ │ <────── │ Worker  │
│  (Publish)  │         │  (Queue) │         │(Consume)│
└─────────────┘         └──────────┘         └─────────┘
      │                                            │
      │                                            │
      ▼                                            ▼
┌─────────────┐                            ┌─────────────┐
│  Database   │                            │   Email     │
│             │                            │  Notifications
└─────────────┘                            └─────────────┘
```

#### **1. WebAPI objavljuje poruke (Publish)**
Kada API treba da uradi nešto asinkrono (npr. poslati email):
```csharp
// U Service klasi
_messageService.PublishEmail("user@example.com", "Subject", "Body");
```
API **ne čeka** na slanje emaila, već samo objavljuje poruku u RabbitMQ i odmah nastavlja.

#### **2. RabbitMQ čuva poruke (Queue)**
RabbitMQ je **message broker** - čuva poruke u redovima (queues) dok Worker ne bude spreman da ih obradi.

#### **3. Worker obrađuje poruke (Consume)**
Worker **neprekidno sluša** RabbitMQ redove i automatski obrađuje poruke:
- `NotificationWorker` - prima poruke i kreira Notification u bazi
- `EmailWorker` - prima poruke i šalje emailove

### **Prednosti ovog pristupa:**

✅ **Brži API odgovori** - korisnik ne čeka na sporije operacije (email, notifikacije)

✅ **Skalabilnost** - možemo pokrenuti više Worker instanci ako ima puno posla

✅ **Pouzdanost** - ako API padne, poruke ostaju u RabbitMQ i Worker će ih obraditi kad se API vrati

✅ **Razdvajanje odgovornosti** - API se fokusira na HTTP zahtjeve, Worker na pozadinske zadatke

✅ **Automatske provjere** - Worker može provjeravati overdue rentals, slati reminders, itd.

### **Primjer korištenja:**

```csharp
// U API Controller/Service
// Korisnik se prijavi
public async Task<IActionResult> Login(...)
{
    var response = await _authService.Login(request);
    
    // Objavljujemo notifikaciju u RabbitMQ (brzo!)
    _messageService.PublishNotification(
        userId: response.UserId,
        title: "Welcome Back!",
        message: "You have successfully logged in.",
        type: "Info"
    );
    
    // API odmah vraća token (korisnik ne čeka)
    return Ok(new { token = response.Token });
}

// Worker automatski prima poruku i kreira Notification u bazi
// Korisnik dobije notifikaciju bez čekanja!
```

### **Trenutni Worker Servisi:**

1. **NotificationWorker** (`NotificationWorker.cs`)
   - Prima notifikacije iz RabbitMQ reda `notifications`
   - Kreira `Notification` entitete u bazi
   - Provjerava overdue rentals i šalje notifikacije

2. **EmailWorker** (`EmailWorker.cs`)
   - Prima email zahtjeve iz RabbitMQ reda `emails`
   - Šalje emailove korisnicima preko SMTP

---

## 📦 Struktura Projekta

```
MosPosudit/
├── MosPosudit.Model/          # DTOs, Enums, Messages
│   ├── Requests/              # Request DTOs
│   ├── Responses/             # Response DTOs
│   ├── SearchObjects/         # Search/Filter DTOs
│   └── Enums/                 # Enumeracije
│
├── MosPosudit.Services/       # Biznis logika
│   ├── DataBase/
│   │   ├── Data/              # Entity klase
│   │   └── ApplicationDbContext.cs
│   ├── Interfaces/            # Service interfejsi
│   └── Services/              # Service implementacije
│
├── MosPosudit.WebAPI/         # HTTP API
│   └── Controllers/           # API kontroleri
│
└── MosPosudit.Worker/         # Background servisi
    └── Services/              # Worker implementacije
```

---

## ✅ Checklist za novu funkcionalnost:

- [ ] Kreiran Entity u `DataBase/Data/`
- [ ] Dodat u `ApplicationDbContext`
- [ ] Kreiran Request DTO u `Model/Requests/[Entity]/`
- [ ] Kreiran Response DTO u `Model/Responses/[Entity]/`
- [ ] Kreiran SearchObject u `Model/SearchObjects/`
- [ ] Kreiran Interface u `Services/Interfaces/`
- [ ] Kreiran Service u `Services/Services/`
- [ ] Kreiran Controller u `WebAPI/Controllers/`
- [ ] Ako treba asinkron zadatak → dodati u MessageService i Worker

---

## 🤔 FAQ - Chat/Message Funkcionalnost

### **Da li MessageController treba Interface i Service?**

✅ **DA** - Po arhitekturi projekta, **SVAKI Controller** mora imati:
- **Interface** (`IChatService`) u `MosPosudit.Services/Interfaces/`
- **Service** (`ChatService`) u `MosPosudit.Services/Services/`
- Controller samo poziva Service metode

### **Da li Chat treba biti u Worker ili API/Service?**

✅ **Chat mora biti u API/Service**, a **NE u Worker** iz sljedećih razloga:

#### **1. Sinhrona Operacija**
- Chat poruke moraju biti **odmah dostupne** korisniku
- Kada korisnik pošalje poruku, mora je **odmah vidjeti** u chatu
- Worker obrađuje asinkrono (sa zakašnjenjem), što bi oštetilo UX

#### **2. Real-time Komunikacija**
- Chat zahtijeva **instant feedback**
- Korisnik mora znati da je poruka poslata i vidjeti je odmah
- Worker ne bi mogao garantovati brzu dostupnost

#### **3. Odgovor API-ja**
- API mora vratiti poruku u HTTP odgovoru
- Worker radi u pozadini i ne može vratiti direktan odgovor

### **Šta ONDA ide u Worker za Chat?**

Worker se koristi za **asinkrone notifikacije** vezane za chat:

```csharp
// U ChatService.cs
public async Task<MessageResponse> SendMessage(...)
{
    // 1. Sinhrono - kreira poruku u bazi (ODMAH)
    var message = new Message { ... };
    _context.Messages.Add(message);
    await _context.SaveChangesAsync();
    
    // 2. Asinkrono - pošalji notifikaciju adminu (preko RabbitMQ → Worker)
    _messageService.PublishNotification(
        adminId,
        "New Message",
        "You have received a new message.",
        "NewMessage"
    );
    
    // 3. Vrati poruku korisniku (ODMAH)
    return new MessageResponse { ... };
}
```

**Raspodjela:**
- ✅ **API/Service**: Kreiranje poruke, vraćanje poruke korisniku (sinhrono)
- ✅ **Worker**: Slanje notifikacije adminu da ima novu poruku (asinkrono)

### **Razlika:**

| Operacija | Gdje ide? | Zašto? |
|-----------|-----------|--------|
| Kreiranje poruke u bazi | **API/Service** | Korisnik mora odmah vidjeti poruku |
| Vraćanje poruke korisniku | **API/Service** | Sinhron HTTP odgovor |
| Slanje notifikacije adminu | **Worker** | Admin ne mora odmah znati, može čekati |
| Provjera overdue rentals | **Worker** | Spora operacija, ne utiče na trenutni odgovor |
| Slanje emaila | **Worker** | Spor proces, korisnik ne čeka |

