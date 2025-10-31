## RS2 – Checklist za predaju seminarskog rada

Kratki, praktični koraci koje treba završiti prije predaje na pregled (Razvoj softvera II).

### 1) Obavezna dokumentacija (recommender)
- [ ] Dodati `recommender-dokumentacija.pdf` u repo, sadrži:
  - [ ] Kratki opis korištenog algoritma i implementacije
  - [ ] Putanju i screenshot ključne logike preporuka (source code)
  - [ ] Putanju i screenshot iz pokrenute aplikacije gdje se prikazuju preporuke

### 2) Build mobilne (Android)
- [ ] API adresa za mobilnu app: `10.0.2.2`
- [ ] Očistiti build: 
```bash
flutter clean
```
- [ ] Build APK (release):
```bash
flutter build apk --release
```
- [ ] Provjeriti da je generisan APK na:
`<folder-mobilne-app>/build/app/outputs/flutter-apk/app-release.apk`
- [ ] Test u AVD:
  - [ ] Deinstaliraj staru verziju iz AVD-a
  - [ ] Prevuci `app-release.apk` u AVD za instalaciju
  - [ ] Pokreni i potvrdi ispravnost rada

### 3) Build Windows (desktop)
- [ ] API adresa za desktop app: `localhost`
- [ ] Očistiti build:
```bash
flutter clean
```
- [ ] Build Windows (release):
```bash
flutter build windows --release
```
- [ ] Provjeriti da je generisan .exe na:
`<folder-desktop-app>/build/windows/x64/runner/Release/`
- [ ] Pokrenuti .exe i potvrditi ispravnost rada

### 4) Pakovanje build artefakata
- [ ] ZIP sa šifrom "fit" naziva `fit-build-20gg-mm-dd.zip`, sadrži foldere:
  - [ ] `<folder-mobilne-app>/build/app/outputs/flutter-apk`
  - [ ] `<folder-desktop-app>/build/windows/x64/runner/Release/`
- [ ] Zbog GitHub limita 100MB, koristiti split (npr. na 90MB):
  - [ ] Commit-ovati i dodatne fajlove `.z01`, `.z02`, ...

### 5) Repo i konfiguracija
- [ ] Repo na GitHub-u je PUBLIC i sadrži kompletan source code + build artefakte iznad
- [ ] Ne koristiti HTTPS/SSL (self-signed) za API ako može stvarati probleme (preporuka: HTTP)
- [ ] Konfiguracijski fajlovi (npr. `.env`) MORAJU biti u repo-u:
  - [ ] Ako GitHub dozvoljava: ostaviti originalni `.env`
  - [ ] Ako ne dozvoljava: uključiti ZIP-ovan `.env` sa šifrom "fit" u istom folderu i nazivu
- [ ] Ako `git push` odbije velike fajlove ili osjetljive podatke: uraditi amend i ponovni push:
```bash
git add -A
git commit --amend
git push -f
```

### 6) DL predaja (Zadaci)
- [ ] Postaviti link GitHub repozitorija na DL (Zadaci → aktuelni zadatak → Prijavi temu/Detalji → Link)
- [ ] Na GitHub-u moraju biti i buildani FE fajlovi (iz tač. 4) i recommender dokumentacija (tač. 1)

---

Brza provjera:
- [ ] `recommender-dokumentacija.pdf` sa opisom, putanjama i screenshotovima
- [ ] Android APK buildovan i testiran u AVD (`10.0.2.2`)
- [ ] Windows .exe buildovan i testiran (`localhost`)
- [ ] Artefakti zapakovani u `fit-build-20gg-mm-dd.zip` (split < 100MB) i commit-ovani
- [ ] Repo public, sadrži source + build + konfiguraciju (`.env` ili zip-ovana zamjena)
- [ ] Link repo-a postavljen na DL



