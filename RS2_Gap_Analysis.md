## RS2 – Gap analiza (trenutno stanje vs. zahtjevi/ideja)

Ovaj dokument mapira šta je već implementirano u repozitoriju i šta nedostaje u odnosu na `RS2_Seminar_Checklist.md`, `RS2_Submission_Checklist.md` i ideju `Seminarski_Idea_MosPosudit.md`.

### Mikroservisi / Infrastruktura
- [x] API servis (.NET WebAPI)
- [x] Pomoćni servis (Worker) sa RabbitMQ servisom: `MosPosudit.Worker` (EmailWorker, NotificationWorker)
- [x] Docker-compose.yml postoji
- [ ] Provjera: API -> RabbitMQ publish staze i konkretne poruke za ključne događaje (rezervacija, plaćanje)

### Baza / Modeli (MosPosudit.Services/DataBase/Data)
- [x] Ključne domenske tabele: `Tool`, `Category`, `Rental`, `RentalItem`, `Review`, `Order`, `OrderItem`, `Payment*`, `User`, `UserFavorite`, `ToolImage`, `ToolMaintenanceSchedule`, `MaintenanceLog`, `Notification`, `SystemLog`
- [x] Migrations postoje
- [ ] Potvrditi FK veze/NOT NULL u skladu sa UI validacijom
- [ ] Seed podaci dovoljni za demo/test (DataSeedController postoji)

### API sloj (MosPosudit.WebAPI/Controllers)
- [x] `AuthController`, `UserController`, `NotificationController`, `BaseCrudController`, `DataSeedController`
- [ ] Endpoints za: `Tool`, `Category`, `Rental/Reservation`, `Review`, `Order/Payment`, `Reports` (nije vidljivo u listi kontrolera)
- [ ] Endpoints za preporuke (npr. `/api/recommendations`)

### Servisi (MosPosudit.Services/Services)
- [x] `AuthService`, `UserService`, `MessageService`, `BaseCrudService`
- [ ] Servisi za `Tool`, `Category`, `Rental`, `Review`, `Order/Payment`, `Reports`
- [ ] Servis/logika preporuka (algoritam + spremanje/učitavanje modela po potrebi)

### Desktop Flutter (MosPosudit.UI/desktop/lib/screens)
- [x] Prisustvo ekrana: `tools_screen.dart`, `users_screen.dart`, `reservations_screen.dart`, `reports_screen.dart`, `categories_screen.dart`, `dashboard_screen.dart`, `edit_profile_screen.dart`
- [ ] Validacije formi i poruke (u skladu sa RSII standardima)
- [ ] CRUD nad šifrarnicima kompletan (provjera integracije sa API-jem)
- [ ] Izvještaji preuzimanje/print (endpoints + UI)
- [ ] Ne prikazivati ID-ove; dropdown iz baze; UX usklađen

### Mobile Flutter (MosPosudit.UI/mobile/lib)
- [x] `auth_service.dart`, `user_service.dart`, `edit_profile_screen.dart`
- [ ] Ekrani: pregled/pretraga alata, detalji, korpa/rezervacija, plaćanje, recenzije, prikaz preporuka
- [ ] Povezati API adrese preko `--dart-define`
- [ ] Validacije, poruke i tokovi nakon spašavanja

### Autentifikacija / Autorizacija
- [x] Postoji Auth kontroler i servis
- [ ] Provjeriti zaštitu svih endpointa koji trebaju autorizaciju (policies/atributi)
- [ ] README korisnički nalozi (desktop/mobile/test uloge)

### Konfiguracija
- [x] `appsettings.json` prisutan
- [ ] Centralizovati sve konfiguracije: RabbitMQ, SMTP, JWT, ConnectionString, API base URL
- [ ] Flutter `--dart-define` za base URL-ove (desktop i mobile)

### Preporuke (feature iz ideje)
- [ ] Backend: ko-rezervacije + interesovanje (posjete/dodavanja u korpu) + uticaj recenzija
- [ ] API endpointi za dohvat preporuka
- [ ] Desktop: konfiguracija i pregled preporuka
- [ ] Mobile: prikaz preporuka (npr. nakon dodavanja u korpu)
- [ ] Dokument `recommender-dokumentacija.pdf` sa opisom, putanjama i screenshotovima

### Predaja / Artefakti
- [ ] README: pokretanje (docker-compose), test korisnici (desktop/mobile), konfiguracija
- [ ] Build Android APK i Windows EXE; zip „fit-build-20gg-mm-dd.zip“ (split < 100MB)
- [ ] Repo public; konfiguracijski fajlovi prisutni (ili zipovani sa šifrom „fit“)
- [ ] Link na DL postavljen



