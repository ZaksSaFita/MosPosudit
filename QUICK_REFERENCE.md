# Quick Reference - Lokacije Fajlova za Screenshot-e

Ovaj dokument sadrži sve lokacije fajlova koje trebate screenshot-ovati za dokumentaciju seminarskog rada.

---

## 🔍 Backend - Source Code za Screenshot-e

### 1. RecommendationService.cs - Glavna Logika Recommender Sistema
**Putanja:** `MosPosudit.Services/Services/RecommendationService.cs`

**Screenshot lokacije:**
- **Linije 28-97:** Metoda `GetHomeRecommendationsAsync()` - Home preporuke algoritam
- **Linije 103-143:** Metoda `GetCartRecommendationsAsync()` - Cart preporuke algoritam
- **Linije 147-165:** Privatna metoda `GetUserFavoriteCategoriesAsync()` - Pronalazi omiljene kategorije
- **Linije 167-199:** Privatna metoda `GetContentBasedRecommendationsAsync()` - Content-based preporuke
- **Linije 201-237:** Privatna metoda `GetPopularRecommendationsAsync()` - Popularne preporuke
- **Linije 239-279:** Privatna metoda `GetTopRatedRecommendationsAsync()` - Top rated preporuke
- **Linije 281-324:** Privatna metoda `GetFrequentlyBoughtTogetherAsync()` - Često kupljeno zajedno
- **Linije 326-382:** Privatna metoda `GetSimilarToolsAsync()` - Slični alati

**Preporuka:** Screenshot linija 28-97 i 103-143 za glavnu logiku.

---

### 2. IRecommendationService.cs - Interface
**Putanja:** `MosPosudit.Services/Interfaces/IRecommendationService.cs`

**Screenshot lokacija:**
- **Sve linije (1-20):** Cijeli interface - prikazuje metode koje recommender servis implementira

---

### 3. RecommendationController.cs - API Controller
**Putanja:** `MosPosudit.WebAPI/Controllers/RecommendationController.cs`

**Screenshot lokacije:**
- **Linije 18-34:** Metoda `GetHomeRecommendations()` - API endpoint za home preporuke
- **Linije 36-52:** Metoda `GetCartRecommendations()` - API endpoint za cart preporuke

**Preporuka:** Screenshot linija 18-52 za sve API endpoint-e.

---

### 4. RecommendationSettings.cs - Model za Postavke
**Putanja:** `MosPosudit.Services/DataBase/Data/RecommendationSettings.cs`

**Screenshot lokacija:**
- **Sve linije (1-36):** Cijeli model - prikazuje težine (weights) za različite tipove preporuka

---

## 📱 Frontend - Flutter UI za Screenshot-e

### 5. recommendation_service.dart - Flutter Servis
**Putanja:** `MosPosudit.UI/shared/lib/services/recommendation_service.dart`

**Screenshot lokacije:**
- **Linije 12-33:** Metoda `getHomeRecommendations()` - Poziv API-ja za home preporuke
- **Linije 36-51:** Metoda `getCartRecommendations()` - Poziv API-ja za cart preporuke

**Preporuka:** Screenshot linija 12-51 za obje metode.

---

### 6. home_screen.dart - Prikaz Home Preporuka
**Putanja:** `MosPosudit.UI/mobile/lib/screens/home_screen.dart`

**Screenshot lokacije:**
- **Linija 52:** Poziv `getHomeRecommendations()` - Učitavanje preporuka
- **Linije 402-423:** Prikaz "Recommended for you" sekcije u UI-u

**Preporuka:** Screenshot linija 52 za poziv API-ja i linija 402-423 za prikaz u UI-u.

---

### 7. cart_recommendations_dialog.dart - Dialog za Cart Preporuke
**Putanja:** `MosPosudit.UI/mobile/lib/widgets/cart_recommendations_dialog.dart`

**Screenshot lokacije:**
- **Linije 60-124:** Build metoda za dialog - Prikaz dialog-a sa preporukama
- **Linije 234-277:** Build metoda za recommendation item - Prikaz pojedinačne preporuke u listi

**Preporuka:** Screenshot linija 60-124 za dialog i linija 234-277 za item.

---

### 8. main.dart - Poziv Cart Preporuka
**Putanja:** `MosPosudit.UI/mobile/lib/main.dart`

**Screenshot lokacija:**
- **Linije 1099-1122:** Metoda `_showCartRecommendations()` - Poziv cart preporuka kada se dodaje u korpu

**Preporuka:** Screenshot linija 1099-1122.

---

## 📸 Screenshot-i Pokrenute Aplikacije

### Mobilna Aplikacija (Android)

#### 1. Home Screen - "Recommended for you" Sekcija
**Lokacija u aplikaciji:**
- Otvoriti mobilnu aplikaciju
- Navigirati na Home Screen (početna stranica)
- Scrollati do sekcije "Recommended for you"
- **Screenshot:** Prikaz preporučenih alata na home screen-u

**Šta screenshot-ovati:**
- Sekcija "Recommended for you" sa prikazom preporučenih alata
- Svaki alat prikazuje: sliku, naziv, cijenu (dnevna stopa)

---

#### 2. Cart Recommendations Dialog
**Lokacija u aplikaciji:**
- Otvoriti mobilnu aplikaciju
- Dodati alat u korpu (klik na "Add to Cart")
- Pojavit će se dialog sa preporukama
- **Screenshot:** Dialog sa preporukama nakon dodavanja u korpu

**Šta screenshot-ovati:**
- Dialog sa naslovom "Recommended For You"
- Lista preporučenih alata (slika, naziv, cijena)
- Mogućnost dodavanja preporučenih alata direktno u korpu
- Dugme "Continue"

---

### Desktop Aplikacija (Windows)

#### 3. Home/Dashboard Screen - Recommended Section (ako postoji)
**Lokacija u aplikaciji:**
- Pokrenuti desktop aplikaciju
- Navigirati na Home/Dashboard
- Pronaći sekciju sa preporukama (ako postoji)
- **Screenshot:** Prikaz preporuka u desktop aplikaciji

**Napomena:** Provjeriti da li desktop aplikacija ima prikaz preporuka na home screen-u.

---

## 🔧 Konfiguracijski Fajlovi za Screenshot-e

### API URL Konfiguracije

#### Android (Mobile)
**Fajl:** `MosPosudit.UI/mobile/lib/core/constants.dart`
- **Linija 5:** `const String _defaultApiUrl = 'http://10.0.2.2:5001/api';`
- **Screenshot:** Linija 1-15 (kompletan fajl sa konfiguracijom)

#### Desktop (Windows)
**Fajl:** `MosPosudit.UI/shared/lib/core/config.dart`
- **Linija 8:** `static AppConfig get instance => _instance ??= AppConfig(apiBaseUrl: 'http://localhost:5001/api');`
- **Screenshot:** Linija 1-11 (kompletan fajl sa konfiguracijom)

---

## 📝 Checklist za Screenshot-e

### Source Code Screenshot-i:

- [ ] ✅ `RecommendationService.cs` - Linije 28-97 (GetHomeRecommendationsAsync)
- [ ] ✅ `RecommendationService.cs` - Linije 103-143 (GetCartRecommendationsAsync)
- [ ] ✅ `IRecommendationService.cs` - Sve linije (Interface)
- [ ] ✅ `RecommendationController.cs` - Linije 18-52 (API endpoints)
- [ ] ✅ `RecommendationSettings.cs` - Sve linije (Model)
- [ ] ✅ `recommendation_service.dart` - Linije 12-51 (Flutter servis)
- [ ] ✅ `home_screen.dart` - Linija 52 (Poziv API-ja)
- [ ] ✅ `home_screen.dart` - Linije 402-423 (Prikaz u UI-u)
- [ ] ✅ `cart_recommendations_dialog.dart` - Linije 60-124 (Dialog)
- [ ] ✅ `cart_recommendations_dialog.dart` - Linije 234-277 (Item)
- [ ] ✅ `main.dart` - Linije 1099-1122 (Poziv cart preporuka)
- [ ] ✅ `constants.dart` - Linija 5 (Android API URL)
- [ ] ✅ `config.dart` - Linija 8 (Windows API URL)

### Pokrenuta Aplikacija Screenshot-i:

- [ ] ✅ Home Screen - "Recommended for you" sekcija (Mobilna)
- [ ] ✅ Cart Recommendations Dialog (Mobilna)
- [ ] ✅ Home/Dashboard Screen - Recommended section (Desktop, ako postoji)

---

## 📂 Pregled Strukture Projekta

```
MosPosudit/
├── MosPosudit.Services/
│   ├── Services/
│   │   └── RecommendationService.cs ← Backend glavna logika
│   ├── Interfaces/
│   │   └── IRecommendationService.cs ← Interface
│   └── DataBase/Data/
│       └── RecommendationSettings.cs ← Model postavki
│
├── MosPosudit.WebAPI/
│   └── Controllers/
│       └── RecommendationController.cs ← API Controller
│
├── MosPosudit.UI/
│   ├── mobile/
│   │   ├── lib/
│   │   │   ├── core/
│   │   │   │   └── constants.dart ← Android API URL
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart ← Prikaz home preporuka
│   │   │   └── main.dart ← Poziv cart preporuka
│   │   └── widgets/
│   │       └── cart_recommendations_dialog.dart ← Dialog za cart preporuke
│   │
│   ├── desktop/
│   │   └── lib/
│   │       └── (desktop aplikacija)
│   │
│   └── shared/
│       └── lib/
│           ├── core/
│           │   └── config.dart ← Windows API URL
│           └── services/
│               └── recommendation_service.dart ← Flutter servis
│
└── recommender-dokumentacija.md ← Dokumentacija (treba konvertovati u PDF)
```

---

## 💡 Savjeti za Screenshot-e

1. **Source Code:**
   - Koristiti Visual Studio Code, Visual Studio, ili bilo koji drugi editor
   - Screenshot-ovati kompletan metod/klase sa dovoljno konteksta
   - Uk Inclusion-ati komentare ako postoje (posebno XML dokumentaciju)

2. **Pokrenuta Aplikacija:**
   - Koristiti screenshot alat (Snipping Tool, ShareX, itd.)
   - Uk Inclusion-ati dovoljno konteksta (naslov, dugmad, itd.)
   - Provjeriti da li su preporuke vidljive i jasne

3. **Format Screenshot-a:**
   - Preporučeno: PNG ili JPG format
   - Dobra rezolucija (min 1920x1080 za desktop, min 1080x1920 za mobilni)
   - Čitljiv tekst u screenshot-u

---

## 🎯 Quick Navigation

- **Backend glavna logika:** `MosPosudit.Services/Services/RecommendationService.cs`
- **API Controller:** `MosPosudit.WebAPI/Controllers/RecommendationController.cs`
- **Flutter servis:** `MosPosudit.UI/shared/lib/services/recommendation_service.dart`
- **Home preporuke UI:** `MosPosudit.UI/mobile/lib/screens/home_screen.dart`
- **Cart preporuke UI:** `MosPosudit.UI/mobile/lib/widgets/cart_recommendations_dialog.dart`

---

## ✅ Finalni Checklist

Prije predaje provjeriti:

- [ ] ✅ Svi source code screenshot-i su pripremljeni
- [ ] ✅ Screenshot-i pokrenute aplikacije su pripremljeni
- [ ] ✅ Dokumentacija recommender sistema je kreirana (`recommender-dokumentacija.md`)
- [ ] ✅ Dokumentacija je konvertovana u PDF (`recommender-dokumentacija.pdf`)
- [ ] ✅ PDF dokumentacija je commit-ovana na git repozitorij
- [ ] ✅ Android build je pripremljen (.apk fajl)
- [ ] ✅ Windows build je pripremljen (.exe fajl)
- [ ] ✅ Build folderi su zip-ovani sa šifrom "fit"
- [ ] ✅ Split arhive su kreirane (90 MB po dijelu)
- [ ] ✅ Svi zip fajlovi su commit-ovani na git
- [ ] ✅ Link git repozitorija je postavljen na DL sistem

