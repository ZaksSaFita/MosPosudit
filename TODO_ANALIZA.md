# Analiza RS2 Checklist - Šta treba uraditi/izmjeniti

## ✅ ŠTO JE VEĆ SPREМNO

### Backend
- ✅ API i Worker servisi postoje
- ✅ RabbitMQ postavljen u docker-compose
- ✅ Kontroleri: Auth, User, Tool, Category, Review, Rental, Payment, Message, Notification, UserFavorite
- ✅ Servisi: Auth, User, Tool, Category, Review, Rental, Message, Notification, Chat, PayPal
- ✅ Baza ima dovoljno tabela (10+)

---

## 🔴 KRITIČNO - MORA SE URADITI

### 1. **AUTORIZACIJA** (RS2_Seminar_Checklist.md - tačka 8) ✅ ZAVRŠENO
- ✅ `BaseCrudController` - odkomentarisan `[Authorize]` atribut
- ✅ `Delete` metoda - dodana `[Authorize(Roles = "Admin")]`
- ✅ Svi endpointi koji nasljeđuju `BaseCrudController` su sada zaštićeni
- ✅ Public endpointi koriste `[AllowAnonymous]` gdje je potrebno

### 2. **README - TEST KORISNICI** (RS2_Seminar_Checklist.md - tačka 11) ✅ ZAVRŠENO
- ✅ Seed podaci kreiraju korisnike:
  - Desktop: `desktop/test` (Admin role) ✓
  - Mobile: `mobile/test` (User role) ✓
- ✅ README sadrži login credentials

### 3. **KONFIGURACIJA** (RS2_Seminar_Checklist.md - tačka 5) ✅ ZAVRŠENO
- ✅ **Sve konfiguracije prebačene u `.env` fajl**
- ✅ **`.env.example`** kreiran kao template
- ✅ **docker-compose.yml** koristi `.env` varijable
- ✅ **RabbitMQ**: Konfiguracija u `.env` (Host, Username, Password)
- ✅ **SMTP**: Konfiguracija u `.env` (Host, Port, Username, Password, EnableSsl)
- ✅ **JWT**: Konfiguracija u `.env` (Key, Issuer, Audience)
- ✅ **Connection String**: Postoji u `.env`
- ✅ **PayPal**: Konfiguracija u `.env` (ClientId, Secret, Mode, ReturnUrl, CancelUrl)
- ✅ **API Base URL**: Flutter promijenjen da koristi `--dart-define=API_URL=...`
  - Mobile: `constants.dart` koristi `String.fromEnvironment('API_URL')` sa default `10.0.2.2`
  - Desktop: `constants.dart` koristi `String.fromEnvironment('API_URL')` sa default `localhost`
- ✅ **appsettings.json** ostaju za local development bez Docker-a
- ✅ README ažuriran sa uputama za `.env` i `--dart-define`
- ✅ Database name usklađen na `180081` u svim fajlovima

### 4. **IZVJEŠTAJI** (RS2_Seminar_Checklist.md - tačka 4)
- ❌ Nema ReportsController
- ❌ Desktop Flutter ima reports_screen.dart ali nije implementiran
- **Akcija**: 
  - Kreirati ReportsController sa endpointima za izvještaje
  - Implementirati download/print funkcionalnost u desktop Flutter

### 5. **PREPORUKE (RECOMMENDER)** (RS2_Submission_Checklist.md - tačka 1)
- ❌ Potpuno nedostaje
- ❌ Nema algoritma preporuka
- ❌ Nema endpointa za preporuke
- ❌ Nema `recommender-dokumentacija.pdf`
- **Akcija**: 
  - Implementirati algoritam preporuka (npr. collaborative filtering)
  - Kreirati RecommendationsController
  - Implementirati u desktop i mobile Flutter
  - Kreirati dokumentaciju sa opisom, putanjama i screenshotovima

---

## 🟡 VAŽNO - TREBA PROVJERITI/POPRAVITI

### 6. **VALIDACIJA** (RS2_Seminar_Checklist.md - tačka 7)
- ⚠️ Treba provjeriti da li su validacije kompletne
- ⚠️ Poruke moraju biti ispod kontrola (ne u inputu)
- ⚠️ Nakon spašavanja: forma se čisti i lista se refresha
- **Akcija**: Provjeriti sve forme u desktop i mobile Flutter

### 7. **UI/UX** (RS2_Seminar_Checklist.md - tačka 9)
- ⚠️ Ne prikazivati ID-ove korisniku
- ⚠️ Dropdown iz baze (ne unos ID-a)
- ⚠️ Potvrde za nepovratne akcije
- ⚠️ Back dugme
- **Akcija**: Provjeriti sve ekrane i ispraviti gdje nedostaje

### 8. **SEED PODACI** (RS2_Gap_Analysis.md)
- ⚠️ SeedService postoji, ali treba provjeriti da li kreira:
  - Korisnike: `desktop/test` i `mobile/test`
  - Dovoljno testnih podataka za demo
- **Akcija**: Provjeriti i dopuniti SeedService

### 9. **RABBITMQ PUBLISH** (RS2_Gap_Analysis.md)
- ⚠️ MessageService postoji, ali treba provjeriti da li API zaista šalje poruke za:
  - Rezervacije/rentals
  - Plaćanja
  - Ključne događaje
- **Akcija**: Provjeriti RentalService i PaymentService da šalju poruke

### 10. **MOBILE FLUTTER** (RS2_Gap_Analysis.md)
- ⚠️ Ekrani možda nedostaju ili nisu kompleti:
  - Pregled/pretraga alata
  - Detalji alata
  - Korpa/rezervacija
  - Plaćanje
  - Recenzije
  - Prikaz preporuka
- **Akcija**: Provjeriti šta nedostaje i implementirati

### 11. **DESKTOP FLUTTER** (RS2_Gap_Analysis.md)
- ⚠️ CRUD nad šifrarnicima - provjeriti kompletnost
- ⚠️ Validacije formi
- ⚠️ Izvještaji (download/print)
- **Akcija**: Provjeriti i dopuniti gdje nedostaje

---

## 🟢 SPREMNO ZA PREDAJU - TREBA BUILDOVATI

### 12. **BUILD ARTEFAKTI** (RS2_Submission_Checklist.md - tačka 2-4)
- ❌ Android APK nije buildovan
- ❌ Windows EXE nije buildovan
- ❌ ZIP sa build artefaktima nije kreiran
- **Akcija**: 
  ```bash
  # Android
  cd MosPosudit.UI/mobile
  flutter clean
  flutter build apk --release --dart-define=API_URL=http://10.0.2.2:5001
  
  # Windows
  cd MosPosudit.UI/desktop
  flutter clean
  flutter build windows --release --dart-define=API_URL=http://localhost:5001
  ```

### 13. **REPO I PREDAJА** (RS2_Submission_Checklist.md - tačka 5-6)
- ⚠️ Repo mora biti PUBLIC
- ⚠️ Konfiguracijski fajlovi moraju biti u repo (ili zip-ovani sa šifrom "fit")
- ⚠️ Link na DL postavljen
- **Akcija**: Provjeriti i finalizovati

---

## 📋 PRIORITETNI REDOSLIJED

### FAZA 1 - Kritično (Mora biti urađeno)
1. ✅ Autorizacija - odkomentarisati [Authorize]
2. ✅ Provjeriti seed podatke za desktop/mobile korisnike
3. ✅ Flutter preći na --dart-define umjesto hardkodiranih IP adresa
4. ✅ Kreirati ReportsController i implementirati izvještaje

### FAZA 2 - Važno (Preporučeno)
5. ✅ Implementirati Recommender sistem (algoritam + API + UI)
6. ✅ Provjeriti i popraviti validacije u Flutter aplikacijama
7. ✅ Provjeriti UI/UX (ID-ovi, dropdowni, potvrde)
8. ✅ Provjeriti RabbitMQ publish u RentalService i PaymentService
9. ✅ Kompletirati mobile Flutter ekrane

### FAZA 3 - Predaja (Prije deadline-a)
10. ✅ Build Android APK i Windows EXE
11. ✅ Kreirati recommender-dokumentacija.pdf
12. ✅ ZIP build artefakte
13. ✅ Finalna provjera README i repo-a

---

## 📝 DODATNE NAPOMENE

### docker-compose.yml
- ⚠️ Baza je `220116` umjesto `180081` - provjeriti koji je pravi broj indeksa
- ⚠️ Treba ažurirati connection string ako je potrebno

### Flutter
- ⚠️ Mobile koristi hardkodiranu IP adresu umjesto `--dart-define`
- ⚠️ Desktop možda također koristi hardkodirane vrijednosti

### Konfiguracija
- ⚠️ PayPal credentials su hardkodirani u docker-compose - trebaju biti u .env ili appsettings.json

---

## ✅ FINALNA PROVJERA (Brza samoprovjera prije predaje)

- [ ] 2+ servisa u docker-compose (API + worker) + RabbitMQ + DB
- [ ] API šalje poruke; worker troši i izvršava posao
- [ ] ≥ 10 „glavnih" tabela (bez šifrarnika/Identity/M2M bez atributa)
- [ ] CRUD nad šifrarnicima; izvještaji (download/print)
- [ ] Pretraga u listama; validacije kompletne i jasne; UX očekivan
- [ ] Nema ID-ova na UI; dropdown iz baze; geokoordinate kroz alat/kartu
- [ ] Konfiguracije centralizovane; Flutter kroz `--dart-define`
- [ ] README sa pokretanjem i test korisnicima; repo public
- [ ] Aplikacija radi „out of the box" bez ručnih izmjena
- [ ] Recommender dokumentacija postoji

