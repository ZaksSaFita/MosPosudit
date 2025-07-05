# MošPosudit Mobile App - Klijent

Android aplikacija za klijentski dio MošPosudit sistema pozajmljivanja alata.

## Preduvjeti

- Flutter SDK (3.32.5 ili noviji)
- Android Studio
- Android emulator ili fizički Android uređaj

## Instalacija

1. Navigirajte u mobile folder:
```bash
cd MošPosudit.UI/mobile/mosposudit_mobile
```

2. Instalirajte dependencies:
```bash
flutter pub get
```

3. Pokrenite aplikaciju:
```bash
flutter run
```

## Funkcionalnosti

### Pregled alata
- Lista svih dostupnih alata
- Detalji o alatima
- Pretraga i filtriranje
- Kategorije alata

### Kreiranje pozajmica
- Odabir alata za pozajmljivanje
- Određivanje perioda pozajmice
- Potvrda pozajmice
- Status pozajmice

### Moje pozajmice
- Pregled aktivnih pozajmica
- Historija pozajmica
- Detalji o pozajmicama
- Status pozajmica

### Profil korisnika
- Pregled korisničkih podataka
- Uređivanje profila
- Promjena lozinke
- Historija aktivnosti

## API Endpoints

Aplikacija se povezuje sa backend API-jem na:
- `https://localhost:7001/api/Auth/login`

## Test podaci

- **Korisničko ime**: `mobile`
- **Lozinka**: `test`

## Struktura

```
mosposudit_mobile/
├── lib/
│   └── main.dart          # Glavna aplikacija sa klijentskim funkcionalnostima
├── android/               # Android konfiguracija
├── pubspec.yaml           # Dependencies
└── README.md             # Ova datoteka
```

## Dependencies

- `http: ^1.1.0` - Za HTTP zahteve
- `shared_preferences: ^2.2.2` - Za čuvanje podataka

## Navigacija

Aplikacija koristi BottomNavigationBar za navigaciju:
- **Alati**: Pregled dostupnih alata
- **Moje pozajmice**: Pregled pozajmica korisnika
- **Profil**: Korisnički profil i postavke

## UI/UX

- Moderni Material Design 3
- Intuitivna navigacija
- Responsive dizajn
- Optimizovano za mobilne uređaje 