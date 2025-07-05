# MošPosudit UI

Flutter aplikacije za MošPosudit sistem pozajmljivanja alata.

## Struktura

```
MosPosudit.UI/
├── mobile/
│   ├── mosposudit_mobile/     # Klijentska Android aplikacija
│   └── README.md
├── desktop/
│   ├── mosposudit_desktop/    # Administrativna Windows aplikacija
│   └── README.md
└── README.md                  # Ova datoteka
```

## Aplikacije

### Desktop App (Administrativni dio)
- **Lokacija**: `MosPosudit.UI/desktop/mosposudit_desktop/`
- **Platforma**: Windows
- **Funkcionalnosti**: 
  - Dashboard sa statistikama
  - Upravljanje alatima (CRUD)
  - Upravljanje kategorijama (CRUD)
  - Upravljanje korisnicima (CRUD)
  - Upravljanje pozajmicama
  - Izvještavanje
- **Test podaci**: `desktop` / `test`
- **Pokretanje**: `cd MosPosudit.UI/desktop/mosposudit_desktop && flutter run -d windows`

### Mobile App (Klijentski dio)
- **Lokacija**: `MosPosudit.UI/mobile/mosposudit_mobile/`
- **Platforma**: Android
- **Funkcionalnosti**:
  - Pregled dostupnih alata
  - Kreiranje pozajmica
  - Pregled mojih pozajmica
  - Profil korisnika
- **Test podaci**: `mobile` / `test`
- **Pokretanje**: `cd MosPosudit.UI/mobile/mosposudit_mobile && flutter run`

## Preduvjeti

- Flutter SDK 3.32.5 ili noviji
- Android Studio (za mobile app)
- Visual Studio 2022 sa Windows development tools (za desktop app)

## Instalacija i pokretanje

### Desktop App (Administracija)
```bash
cd MosPosudit.UI/desktop/mosposudit_desktop
flutter pub get
flutter run -d windows
```

### Mobile App (Klijent)
```bash
cd MosPosudit.UI/mobile/mosposudit_mobile
flutter pub get
flutter run
```

## API Povezivanje

Obje aplikacije se povezuju sa backend API-jem na:
- `https://localhost:7001/api/Auth/login`

## Funkcionalnosti

### Desktop App - Administrativni dio
- **Dashboard**: Pregled statistika (broj alata, korisnika, pozajmica)
- **Upravljanje alatima**: CRUD operacije za alate
- **Upravljanje kategorijama**: CRUD operacije za kategorije
- **Upravljanje korisnicima**: CRUD operacije za korisnike
- **Upravljanje pozajmicama**: Pregled i upravljanje pozajmicama
- **Izvještaji**: Generisanje izvještaja

### Mobile App - Klijentski dio
- **Pregled alata**: Lista dostupnih alata za pozajmljivanje
- **Kreiranje pozajmica**: Proces pozajmljivanja alata
- **Moje pozajmice**: Pregled aktivnih i historije pozajmica
- **Profil**: Uređivanje profila i lozinke

## Test podaci

### Desktop aplikacija
- Korisničko ime: `desktop`
- Lozinka: `test`

### Mobile aplikacija
- Korisničko ime: `mobile`
- Lozinka: `test`

## Dependencies

Obje aplikacije koriste:
- `http: ^1.1.0` - Za HTTP zahteve
- `shared_preferences: ^2.2.2` - Za čuvanje podataka

## Testiranje

Da biste testirali aplikacije:

1. Pokrenite backend API server
2. Pokrenite desktop aplikaciju za administraciju
3. Pokrenite mobile aplikaciju za klijente
4. Testirajte login sa test podacima
5. Testirajte funkcionalnosti

## Build

### Desktop App
```bash
cd MosPosudit.UI/desktop/mosposudit_desktop
flutter build windows
```

### Mobile App
```bash
cd MosPosudit.UI/mobile/mosposudit_mobile
flutter build apk
```

## Arhitektura

Aplikacije su dizajnirane prema uputama za seminarski rad:
- **Desktop**: Administrativni dio sa CRUD operacijama i izvještavanjem
- **Mobile**: Klijentski dio za pregled usluga i kreiranje narudžbi
- **Single codebase**: Isti kod se koristi za različite platforme unutar svake aplikacije 