## RS2 Seminarski – sažetak zahtjeva i checklist

Ovaj dokument je kratki, praktični checklist ključnih zahtjeva iz uputa za seminarski rad (Razvoj softvera II). Koristi ga za planiranje, implementaciju i finalnu provjeru prije predaje.

### 1) Prijava teme
- [ ] Tema NIJE klasična prodaja proizvoda (ne bazirati na eProdaja/eCommerce funkcionalnostima)
- [ ] Ako je grupni rad: svaki član predaje vlastitu prijavu sa jasno podijeljenim odgovornostima (API, desktop, mobile) i mockup-ovima
- [ ] Mockup-ovi su konzistentni, UI/UX prikladni, nisu snimke gotovih ekrana
- [ ] Prijava predata na DL u roku; čekati odobrenje prije implementacije

### 2) Arhitektura i servisi (mikroservisi + docker)
- [ ] Minimalno 2 odvojena servisa/kontejnera:
  - [ ] Glavni servis: REST API (služi desktop i mobile)
  - [ ] Pomoćni servis: npr. worker/consumer/notifier (odvojen projekt/kontejner)
- [ ] RabbitMQ posrednik:
  - [ ] API šalje poruke
  - [ ] Worker sluša i obrađuje asinhrono (email, log, notifikacije...)
- [ ] docker-compose.yml uključuje: API, pomoćni servis, RabbitMQ, baza; mrežno povezani i funkcionalni
- [ ] Hangfire unutar API-ja se NE računa kao drugi servis

### 3) Backend/DB standardi
- [ ] Backend: C# (.NET), VS 2022/VS Code
- [ ] Baza: SQL Server ili drugi relacioni DB
- [ ] Baza sadrži ≥ 10 tabela (NE računati referentne/šifrarnike, Asp.Net Identity tabele, čiste M2M bez dodatnih atributa)
- [ ] Sve ključne funkcionalnosti podržane adekvatnim tabelama (ne samo šifrarnici)
- [ ] Svi odnosi FK definisani; obavezna polja kao NOT NULL i u skladu sa UI validacijom
- [ ] Dovoljno testnih podataka; može i kroz migracije
- [ ] Code First ili Database First dozvoljeno; SP-ovi opciono

### 4) Aplikacijske komponente i funkcionalnosti
- [ ] Desktop (admin) dio:
  - [ ] CRUD nad svim referentnim podacima (šifrarnici)
  - [ ] Izvještavanje (download/print)
  - [ ] Liste imaju barem jedan parametar pretrage (osim opravdanih izuzetaka)
- [ ] Mobile (klijent):
  - [ ] Pregled usluga/djelatnosti
  - [ ] Kreiranje narudžbe (ako primjenjivo)
  - [ ] Historija aktivnosti (narudžbe/usluge)
  - [ ] Pregled/izmjena profila
- [ ] Jednostavniji modul preporuke (poznati algoritam) ILI Identity Server (napredna autentifikacija)
- [ ] Sve funkcionalnosti iz prijave implementirane 1:1 (npr. color-coded kalendar mora biti takav, ne običan)

### 5) Konfiguracija (centralizovano, bez hardkodiranja)
- [ ] Svi konfiguracijski podaci u config fajlovima (NE u kodu):
  - [ ] RabbitMQ: host, port, queue/exchange, sender
  - [ ] SMTP: host, username, password, SSL, port
  - [ ] Stripe key (ako primjenjivo)
  - [ ] JWT key
  - [ ] Connection string
  - [ ] API base URL
- [ ] Flutter adrese putem `flutter run --dart-define`

### 6) Programski kod i UI kontrole
- [ ] Nema mrtvog/neiskorištenog koda u projektu
- [ ] Na formama postoje samo kontrole sa implementiranom funkcionalnošću
- [ ] Kontrole učitavaju samo relevantne podatke
- [ ] Dropdown liste pune se iz baze (npr. Gradovi)
- [ ] Pravilne kontrole za tipove podataka: checkbox/switch za bool, DateTime picker za datume, dropdown za odabire, geokoordinate preko alata/karti (ne ručni unos u textbox)

### 7) Validacija unosa (potpuna i jasna)
- [ ] Kompletna validacija na dodavanju/uređivanju
- [ ] Jasne poruke o formatu/ograničenjima (npr. broj transakcijskog računa)
- [ ] Ne tražiti nepotrebne unose (npr. promjena lozinke samo uz eksplicitnu akciju; admin ne unosi staru lozinku; korisnik potvrđuje staru pri promjeni svoje lozinke)
- [ ] Validacije prikazane ispod kontrola (ne u inputu niti kao dijalog)
- [ ] Email/telefon formatno validirani
- [ ] Nakon uspjeha: jasna specifična poruka (ne „Success/Bad request“)
- [ ] Nakon spašavanja: forma se čisti; lista automatski prikazuje novi zapis

### 8) Autentifikacija i autorizacija
- [ ] Implementirana autentifikacija korisnika
- [ ] Svi zaštićeni endpointi pokriveni i bez neautoriziranog pristupa

### 9) UI/UX
- [ ] Čitljiv, konzistentan dizajn; bez prejakih boja/transparentnosti
- [ ] Očekivani UX elementi (npr. „X“ za zatvaranje)
- [ ] Potvrde za nepovratne akcije (npr. slanje narudžbe); upozorenja za brisanje
- [ ] Labele i vrijednosti poravnate; koristiti dvije kolone ili jasne redove
- [ ] Ikonice po potrebi (npr. 🗓️, 🚗, ⛽, 💰)
- [ ] Kontrole se ne preklapaju; slike ne zauzimaju > 50% forme
- [ ] Navigacija pregledna, uključuje „Back“
- [ ] Izvještaji dostupni za preuzimanje i ispis
- [ ] Ne prikazivati ID-ove iz baze korisniku; referentne tabele kroz dropdown (ne unos ID-a)

### 10) Flutter (desktop i mobile)
- [ ] Koristiti najnoviji stabilni Flutter i biblioteke
- [ ] Putanje ka API-ju i ostale vrijednosti preko `--dart-define`

### 11) Readme i predaja
- [ ] GitHub repo je PUBLIC; ispravan .gitignore
- [ ] README sadrži:
  - [ ] Korake pokretanja (bez izmjene koda/linkova/portova/connection stringova nakon kloniranja)
  - [ ] Testne korisnike:
    - [ ] Desktop: korisničko ime `desktop`, lozinka `test`
    - [ ] Mobile: korisničko ime `mobile`, lozinka `test`
    - [ ] Ako više uloga: korisničko ime = nazivUloge, lozinka `test`
- [ ] Aplikacija se pokreće i radi stabilno na tuđem okruženju bez intervencija
- [ ] Link na GitHub postavljen na DL (Zadaci → Prijavi temu/Detalji → Link)
- [ ] Testirano na drugim mašinama okruženjima
- [ ] Poštovati dokument „RSII_Upute_za_predaju_seminarskog_rada“
- [ ] Nakon roka ne mijenjati repo (inače se ne evaluira ta promjena)

### 12) Odbrana
- [ ] Spremnost na implementaciju zadatih funkcionalnosti na odbrani (API, Flutter desktop & mobile)
- [ ] U grupi: svi dobro poznaju sve dijelove sistema

---

### Brza samoprovjera prije predaje
- [ ] 2+ servisa u docker-compose (API + worker) + RabbitMQ + DB
- [ ] API šalje poruke; worker troši i izvršava posao
- [ ] ≥ 10 „glavnih“ tabela (bez šifrarnika/Identity/M2M bez atributa)
- [ ] CRUD nad šifrarnicima; izvještaji (download/print)
- [ ] Pretraga u listama; validacije kompletne i jasne; UX očekivan
- [ ] Nema ID-ova na UI; dropdown iz baze; geokoordinate kroz alat/kartu
- [ ] Konfiguracije centralizovane; Flutter kroz `--dart-define`
- [ ] README sa pokretanjem i test korisnicima; repo public
- [ ] Aplikacija radi „out of the box“ bez ručnih izmjena


