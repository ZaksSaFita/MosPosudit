# Build Guide - Priprema za Predaju Seminarskog Rada

Ovaj vodič će vam pomoći da pripremite sve potrebne fajlove za predaju seminarskog rada.

---

## 📱 Build Android Aplikacije

### Koraci:

1. **Postaviti API URL za Android Emulator:**
   - Otvoriti fajl: `MosPosudit.UI/mobile/lib/core/constants.dart`
   - Provjeriti da li je na liniji 5: `const String _defaultApiUrl = 'http://10.0.2.2:5001/api';`
   - ✅ Ovo je standardna adresa za Android Emulator AVD

2. **Očistiti stare build fajlove:**
   ```bash
   cd MosPosudit.UI/mobile
   flutter clean
   ```

3. **Build Android aplikacije:**
   ```bash
   flutter build apk --release
   ```

4. **Lokacija generisanog .apk fajla:**
   ```
   MosPosudit.UI/mobile/build/app/outputs/flutter-apk/app-release.apk
   ```

5. **Provjera ispravnosti rada Android aplikacije u AVD:**
   - Obrisati staru verziju aplikacije u AVD (ako postoji)
   - Prevlačiti .apk fajl u AVD kako biste instalirali aplikaciju
   - Pokrenuti aplikaciju nakon instalacije i provjeriti ispravnost rada

---

## 🖥️ Build Windows Aplikacije

### Koraci:

1. **Postaviti API URL za Windows (localhost):**
   - Otvoriti fajl: `MosPosudit.UI/shared/lib/core/config.dart`
   - Provjeriti da li je na liniji 8: `static AppConfig get instance => _instance ??= AppConfig(apiBaseUrl: 'http://localhost:5001/api');`
   - ✅ Ovo je ispravna adresa za Windows aplikaciju

2. **Očistiti stare build fajlove:**
   ```bash
   cd MosPosudit.UI/desktop
   flutter clean
   ```

3. **Build Windows aplikacije:**
   ```bash
   flutter build windows --release
   ```

4. **Lokacija generisanog .exe fajla:**
   ```
   MosPosudit.UI/desktop/build/windows/x64/runner/Release/
   ```
   - U ovom folderu će biti .exe fajl i svi potrebni DLL fajlovi

5. **Provjera ispravnosti rada Windows aplikacije:**
   - Pokrenuti generisani .exe fajl
   - Provjeriti da li aplikacija radi ispravno

---

## 📦 Priprema Build Foldera za Zip

### Struktura Foldera koji treba zip-ovati:

Prema uputama, trebate kreirati foldere sa sljedećim putanjama:

#### Android Build Folder:
```
folder-mobilne-app/build/app/outputs/flutter-apk/
```
- U ovom folderu treba biti `app-release.apk` fajl

#### Windows Build Folder:
```
folder-desktop-app/build/windows/x64/runner/Release/
```
- U ovom folderu trebaju biti svi fajlovi iz Windows build-a (.exe, DLL fajlovi, itd.)

### ⚠️ Napomena:
Prema vašoj trenutnoj strukturi projekta:
- **Mobilna app:** `MosPosudit.UI/mobile/` → trebalo bi kreirati `folder-mobilne-app/`
- **Desktop app:** `MosPosudit.UI/desktop/` → trebalo bi kreirati `folder-desktop-app/`

**Opcija 1:** Kopirati build foldere u nove foldere:
```bash
# Kreirati folder-mobilne-app i kopirati build folder
mkdir folder-mobilne-app
xcopy /E /I MosPosudit.UI\mobile\build folder-mobilne-app\build

# Kreirati folder-desktop-app i kopirati build folder
mkdir folder-desktop-app
xcopy /E /I MosPosudit.UI\desktop\build folder-desktop-app\build
```

**Opcija 2:** Koristiti postojeće foldere i prilagoditi strukturu:
- Kopirati `MosPosudit.UI/mobile/build/app/outputs/flutter-apk/` → `folder-mobilne-app/build/app/outputs/flutter-apk/`
- Kopirati `MosPosudit.UI/desktop/build/windows/x64/runner/Release/` → `folder-desktop-app/build/windows/x64/runner/Release/`

---

## 🗜️ Zip-ovanje Build Foldera

### Koraci:

1. **Zip-ovati foldere sa šifrom "fit":**
   - Koristiti 7-Zip, WinRAR ili bilo koji drugi kompresioni alat
   - Naziv arhive: `fit-build-20gg-mm-dd.zip` (gdje je gg-mm-dd = godina-mjesec-dan build-a)
   - Primjer: `fit-build-2025-03-05.zip` (za 5. mart 2025.)
   - **Šifra:** `fit`

2. **Split arhiva (90 MB):**
   - Zbog GitHub ograničenja (max 100MB po fajlu), potrebno je kreirati split arhive
   - Veličina svakog dijela: **90 MB**
   - Ovo će generisati dodatne fajlove: `fit-build-2025-03-05.z01`, `fit-build-2025-03-05.z02`, itd.

3. **Fajlovi koje treba commit-ovati:**
   - `fit-build-2025-03-05.zip`
   - `fit-build-2025-03-05.z01` (ako postoji)
   - `fit-build-2025-03-05.z02` (ako postoji)
   - itd.

---

## 🔧 Provjera Konfiguracija

### API URL Provjera:

#### Android (Mobile):
**Fajl:** `MosPosudit.UI/mobile/lib/core/constants.dart`
```dart
const String _defaultApiUrl = 'http://10.0.2.2:5001/api';
```
✅ Provjeriti da li je ovo postavljeno ispravno za Android Emulator

#### Windows (Desktop):
**Fajl:** `MosPosudit.UI/shared/lib/core/config.dart`
```dart
static AppConfig get instance => _instance ??= AppConfig(apiBaseUrl: 'http://localhost:5001/api');
```
✅ Provjeriti da li je ovo postavljeno ispravno za Windows aplikaciju

---

## 📝 Checklist za Predaju

### Prije predaje provjeriti:

- [ ] ✅ Android aplikacija je build-ana i .apk fajl je generisan
- [ ] ✅ Windows aplikacija je build-ana i .exe fajl je generisan
- [ ] ✅ Build folderi su zip-ovani sa šifrom "fit"
- [ ] ✅ Split arhive su kreirane (90 MB po dijelu)
- [ ] ✅ Svi zip fajlovi (.zip, .z01, .z02, itd.) su commit-ovani na git
- [ ] ✅ Dokumentacija recommender sistema je kreirana (`recommender-dokumentacija.pdf`)
- [ ] ✅ Dokumentacija je commit-ovana na git repozitorij
- [ ] ✅ Link git repozitorija je postavljen na DL sistem (sekcija zadaci)
- [ ] ✅ API URL-ovi su ispravno postavljeni za obje aplikacije
- [ ] ✅ Screenshot-i source code-a su pripremljeni
- [ ] ✅ Screenshot-i pokrenute aplikacije sa preporukama su pripremljeni

---

## 🎯 Brza Komanda za Build

### Android:
```bash
cd MosPosudit.UI/mobile
flutter clean
flutter build apk --release
```

### Windows:
```bash
cd MosPosudit.UI/desktop
flutter clean
flutter build windows --release
```

---

## ⚠️ Važne Napomene

1. **SSL/HTTPS:** Prema uputama, ne koristiti SSL tj. https za pristup API-u, jer self signed certifikati mogu isteći ili biti nevalidni.

2. **Konfiguracijski fajlovi (.env):** Ne postavljati konfiguracijske fajlove na DL sistem, jer oni trebaju biti sastavni dio git repozitorija.

3. **Git Commit:** Ako git push ne uspije zbog veličine fajlova, koristiti `git amend` da bi modifikovali zadnji commit, a zatim ponovo `git push`.

4. **Split Arhive:** U slučaju split arhive, obično se kreiraju dodatni fajlovi sa ekstenzijom ".z01", ".z02" itd., i te fajlove također potrebno commit-ovati.

---

## 📍 Pregled Lokacija

### Android Build:
- Build komanda: `MosPosudit.UI/mobile/`
- Output: `MosPosudit.UI/mobile/build/app/outputs/flutter-apk/app-release.apk`

### Windows Build:
- Build komanda: `MosPosudit.UI/desktop/`
- Output: `MosPosudit.UI/desktop/build/windows/x64/runner/Release/`

### Dokumentacija:
- Recommender dokumentacija: `recommender-dokumentacija.md` (treba konvertovati u PDF)

