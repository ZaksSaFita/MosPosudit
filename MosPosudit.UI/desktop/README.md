# MošPosudit Desktop App - Administracija

Windows desktop aplikacija za administrativni dio MošPosudit sistema pozajmljivanja alata.

## Preduvjeti

- Flutter SDK (3.32.5 ili noviji)
- Visual Studio 2022 sa Windows development tools
- Windows 10 ili noviji

## Instalacija

1. Navigirajte u desktop folder:
```bash
cd MošPosudit.UI/desktop/mosposudit_desktop
```

2. Instalirajte dependencies:
```bash
flutter pub get
```

3. Pokrenite aplikaciju:
```bash
flutter run -d windows
```

## Funkcionalnosti

### Dashboard
- Pregled statistika (broj alata, korisnika, pozajmica)
- Brzi pristup glavnim funkcionalnostima

### Upravljanje alatima
- Dodavanje novih alata
- Uređivanje postojećih alata
- Brisanje alata
- Pretraga i filtriranje

### Upravljanje kategorijama
- Dodavanje novih kategorija
- Uređivanje postojećih kategorija
- Brisanje kategorija

### Upravljanje korisnicima
- Pregled svih korisnika
- Dodavanje novih korisnika
- Uređivanje korisničkih podataka
- Aktivacija/deaktivacija korisnika

### Upravljanje pozajmicama
- Pregled svih pozajmica
- Upravljanje statusom pozajmica
- Pretraga po korisnicima i alatima

### Izvještaji
- Generisanje izvještaja o pozajmicama
- Statistike korišćenja
- Export podataka

## API Endpoints

Aplikacija se povezuje sa backend API-jem na:
- `https://localhost:7001/api/Auth/login`

## Test podaci

- **Korisničko ime**: `desktop`
- **Lozinka**: `test`

## Struktura

```
mosposudit_desktop/
├── lib/
│   └── main.dart          # Glavna aplikacija sa admin dashboardom
├── windows/               # Windows konfiguracija
├── pubspec.yaml           # Dependencies
└── README.md             # Ova datoteka
```

## Dependencies

- `http: ^1.1.0` - Za HTTP zahteve
- `shared_preferences: ^2.2.2` - Za čuvanje podataka

## Build za distribuciju

Da biste kreirali executable fajl:

```bash
flutter build windows
```

Executable fajl će biti kreiran u `build/windows/runner/Release/` folderu.

## Navigacija

Aplikacija koristi NavigationRail za navigaciju između različitih sekcija:
- Dashboard
- Alati
- Kategorije
- Korisnici
- Pozajmice
- Izvještaji 