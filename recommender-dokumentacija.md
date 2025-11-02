# Recommender Sistem - Dokumentacija

## 📋 Opis Implementacije Recommender Sistema

Recommender sistem je implementiran kao hibridni sistem koji koristi kombinaciju više pristupa preporuka:

### 1. **Home Recommendations (Preporuke za početnu stranicu)**
Kombinacija tri pristupa:
- **40% Popular/Trending Tools** - Najčešće iznajmljivani alati u posljednjih 30 dana
- **30% Content-Based** - Alati iz kategorija koje korisnik preferira (na osnovu historije narudžbi u posljednjih 90 dana)
- **30% Top Rated** - Alati sa prosječnom ocjenom ≥ 4.0 i najmanje 2 recenzije

### 2. **Cart Recommendations (Preporuke pri dodavanju u korpu)**
Kombinacija dva pristupa:
- **60% Frequently Bought Together** - Alati koji su se često kupovali zajedno sa trenutnim alatom
- **40% Similar Tools** - Alati iz iste kategorije sa sličnom ocjenom (±1.0)

### 3. **Fallback Mehanizmi**
Sistem ima višestruke fallback mehanizme da osigura da korisnik uvijek dobije preporuke ako postoje dostupni alati u sistemu.

---

## 📂 Putanje i Lokacije Source Code-a

### Backend - Glavna Logika Recommender Sistema

#### 1. **RecommendationService.cs** - Glavna logika recommender sistema
**Putanja:** `MosPosudit.Services/Services/RecommendationService.cs`

Ovaj fajl sadrži:
- `GetHomeRecommendationsAsync()` - Metoda za dobijanje preporuka za početnu stranicu (linije 28-97)
- `GetCartRecommendationsAsync()` - Metoda za dobijanje preporuka pri dodavanju u korpu (linije 103-143)
- Privatne helper metode:
  - `GetUserFavoriteCategoriesAsync()` - Pronalazi omiljene kategorije korisnika (linije 147-165)
  - `GetContentBasedRecommendationsAsync()` - Content-based preporuke (linije 167-199)
  - `GetPopularRecommendationsAsync()` - Popularne preporuke (linije 201-237)
  - `GetTopRatedRecommendationsAsync()` - Najbolje ocjenjene preporuke (linije 239-279)
  - `GetFrequentlyBoughtTogetherAsync()` - Često kupljeno zajedno (linije 281-324)
  - `GetSimilarToolsAsync()` - Slični alati (linije 326-382)

**Screenshot lokacija:** Otvoriti fajl i napraviti screenshot linija 28-97 (GetHomeRecommendationsAsync) i 103-143 (GetCartRecommendationsAsync)

#### 2. **IRecommendationService.cs** - Interface za recommender servis
**Putanja:** `MosPosudit.Services/Interfaces/IRecommendationService.cs`

**Screenshot lokacija:** Otvoriti fajl i napraviti screenshot cijelog interface-a

#### 3. **RecommendationController.cs** - API Controller
**Putanja:** `MosPosudit.WebAPI/Controllers/RecommendationController.cs`

Ovaj fajl sadrži:
- `GetHomeRecommendations()` - API endpoint za home preporuke (linije 21-34)
- `GetCartRecommendations()` - API endpoint za cart preporuke (linije 39-52)

**Screenshot lokacija:** Otvoriti fajl i napraviti screenshot linija 21-52

#### 4. **RecommendationSettings.cs** - Model za postavke recommender sistema
**Putanja:** `MosPosudit.Services/DataBase/Data/RecommendationSettings.cs`

**Screenshot lokacija:** Otvoriti fajl i napraviti screenshot cijelog modela

### Frontend - Flutter UI

#### 5. **recommendation_service.dart** - Flutter servis za pozivanje API-ja
**Putanja:** `MosPosudit.UI/shared/lib/services/recommendation_service.dart`

**Screenshot lokacija:** Otvoriti fajl i napraviti screenshot linija 12-33 (getHomeRecommendations) i 36-51 (getCartRecommendations)

#### 6. **home_screen.dart** - Prikaz home preporuka
**Putanja:** `MosPosudit.UI/mobile/lib/screens/home_screen.dart`

**Screenshot lokacija:**
- Otvoriti fajl i napraviti screenshot linija 52 (poziv getHomeRecommendations)
- Otvoriti fajl i napraviti screenshot linija 402-423 (prikaz "Recommended for you" sekcije)

#### 7. **cart_recommendations_dialog.dart** - Dialog za cart preporuke
**Putanja:** `MosPosudit.UI/mobile/lib/widgets/cart_recommendations_dialog.dart`

**Screenshot lokacija:**
- Otvoriti fajl i napraviti screenshot linija 60-124 (build metode za dialog)
- Otvoriti fajl i napraviti screenshot linija 234-277 (build metode za recommendation item)

#### 8. **main.dart** - Poziv cart preporuka
**Putanja:** `MosPosudit.UI/mobile/lib/main.dart`

**Screenshot lokacija:** Otvoriti fajl i napraviti screenshot linija 1099-1122 (_showCartRecommendations metoda)

---

## 📸 Lokacije za Screenshot-e Pokrenute Aplikacije

### Mobilna Aplikacija (Android)

1. **Home Screen - "Recommended for you" sekcija**
   - Otvoriti mobilnu aplikaciju
   - Navigirati na Home Screen (početna stranica)
   - Scrollati do sekcije "Recommended for you"
   - **Screenshot:** Prikaz preporučenih alata na home screen-u

2. **Cart Recommendations Dialog**
   - Otvoriti mobilnu aplikaciju
   - Dodati alat u korpu
   - Pojavit će se dialog sa preporukama
   - **Screenshot:** Dialog sa preporukama nakon dodavanja u korpu

### Desktop Aplikacija (Windows)

1. **Home Screen - Recommended section** (ako postoji)
   - Pokrenuti desktop aplikaciju
   - Navigirati na Home/Dashboard
   - Pronaći sekciju sa preporukama
   - **Screenshot:** Prikaz preporuka u desktop aplikaciji

---

## 🔧 Konfiguracija API URL-a

### Mobilna Aplikacija (Android Emulator)
**Fajl:** `MosPosudit.UI/mobile/lib/core/constants.dart`
- **Linija 5:** `const String _defaultApiUrl = 'http://10.0.2.2:5001/api';`
- Ovo je standardna adresa za Android Emulator AVD

### Desktop Aplikacija (Windows)
**Fajl:** `MosPosudit.UI/shared/lib/core/config.dart`
- **Linija 8:** `static AppConfig get instance => _instance ??= AppConfig(apiBaseUrl: 'http://localhost:5001/api');`

---

## 📊 Algoritam Preporuke - Detaljno

### Home Recommendations Algoritam:

1. **Korak 1:** Dohvaćanje postavki iz baze (težine za različite tipove preporuka)
2. **Korak 2:** Content-Based (30%):
   - Pronalazi 3 najčešće kategorije iz korisnikovih narudžbi (posljednjih 90 dana)
   - Preporučuje alate iz tih kategorija koje korisnik još nije naručivao
   - Sortira po cijeni (dnevna stopa)
3. **Korak 3:** Popular (40%):
   - Pronalazi najčešće iznajmljivane alate u posljednjih 30 dana
   - Sortira po broju narudžbi
4. **Korak 4:** Top Rated (30%):
   - Pronalazi alate sa prosječnom ocjenom ≥ 4.0 i najmanje 2 recenzije
   - Sortira po ocjeni i broju recenzija
5. **Korak 5:** Fallback:
   - Ako nema dovoljno preporuka, popunjava sa bilo kojim dostupnim alatima
   - Ako korisnik nema historiju, vraća default preporuke (40% popular, 60% top rated)

### Cart Recommendations Algoritam:

1. **Korak 1:** Dohvaćanje postavki iz baze
2. **Korak 2:** Frequently Bought Together (60%):
   - Pronalazi sve narudžbe koje sadrže trenutni alat
   - Pronalazi alate koji su se najčešće kupovali u tim istim narudžbama
   - Sortira po učestalosti
3. **Korak 3:** Similar Tools (40%):
   - Pronalazi alate iz iste kategorije
   - Filtrira alate sa sličnom ocjenom (±1.0)
   - Sortira po ocjeni
4. **Korak 4:** Fallback:
   - Ako nema dovoljno, popunjava sa alatima iz iste kategorije
   - Ako još uvijek nema dovoljno, popunjava sa bilo kojim dostupnim alatima

---

## 📝 Napomene

- Sistem koristi Entity Framework Core za pristup bazi podataka
- Sve težine (weights) za različite tipove preporuka su konfigurabilne kroz `RecommendationSettings` tabelu u bazi
- Sistem osigurava da se isti alat ne prikazuje više puta u preporukama (koristi `HashSet<int>` za praćenje dodanih alata)
- Preporuke se prikazuju samo za dostupne alate (`IsAvailable == true` i `Quantity > 0`)

