## MošPosudit – Prijava teme (sažetak)

### 1) Uvod
Problem: potreba za kratkoročnim korištenjem alata bez kupovine ili neugodnog posuđivanja. Rješenje: platforma za brzo i jeftino iznajmljivanje alata.

### 2) Cilj projekta
- Smanjiti troškove korisnicima i olakšati pristup kvalitetnim alatima.
- Desktop: administracija (upravljanje sistemom).
- Mobile: krajnji korisnici (pretraga, rezervacije, plaćanje, recenzije).

### 3) Funkcionalnosti
#### 3.1 Desktop (admin)
- Prijava na aplikaciju
- Upravljanje inventarom alata (CRUD, pretraga, filteri)
- Upravljanje korisnicima (CRUD, pretraga, filteri)
- Upravljanje rezervacijama (pregled, storno/izmjena, pretraga, filteri)
- Moderacija recenzija (brisanje/izmjena; uticaj na preporuke)
- Konfiguracija sistema preporuke
- Generisanje izvještaja

#### 3.2 Mobile (klijent)
- Prijava i registracija
- Pregled i pretraga alata (kategorije, search, filteri, detalji, dodavanje u korpu)
- Rezervacija alata (odabir perioda, provjera dostupnosti, potvrda)
- Plaćanje (validacija, rezultat transakcije, QR kod za preuzimanje)
- Recenziranje (naslov, ocjena 1–5, komentar, slike)
- Prikaz preporuka (u toku kupovine/rezervacije)

### 4) Mockups (opis glavnih ekrana)
- Desktop:
  - Upravljanje korisničkim nalozima (search/filter, CRUD)
  - Inventar alata (lista, search/filter, CRUD)
  - Rezervacije (lista/detalji, storno/izmjena)
  - Moderacija recenzija (pregled, uređivanje/brisanje)
- Mobile:
  - Pretraga alata (po kategorijama, quick add, detalji)
  - Rezervacija (odabir perioda, dostupnost, potvrda)
  - Plaćanje (forma, potvrda, QR)
  - Recenzije (forma sa ocjenom i slikama)
  - Preporuke (notifikacija/sekcija sa predloženim alatima)

### 5) Arhitektura
- .NET Core Web API (REST) + SQL Server
- Mikroservisna arhitektura sa RabbitMQ (asinhrone obrade: e-mail/notifikacije/obrada događaja)
- Desktop: admin UI (Flutter desktop)
- Mobile: klijentska aplikacija (Flutter mobile)

### 6) Sistem preporuke (koncept)
- Ko-kupovina/ko-rezervacije: ako se Alat_A i Alat_B često rezervišu zajedno, preporuči Alat_B kada korisnik izabere Alat_A
- Interesovanje: ako korisnik često posjećuje stranicu alata/kategorije, preporučiti slične alate iz te kategorije
- Recenzije: viša prosječna ocjena daje veću šansu da alat bude preporučen

### 7) Zaključak
MošPosudit omogućava brzo iznajmljivanje bez kupovine; desktop admin dio pojednostavljuje upravljanje inventarom/rezervacijama/izvještajima; mobile dio korisniku omogućava pretragu, rezervaciju, plaćanje i recenzije uz pametne preporuke.



