# Heroku CLI Kurulumu ve İlk Adımlar

## 1. Heroku CLI Kurulumu

### Windows İçin

**Seçenek A: Installer (Önerilen)**
1. Şu adresten indirin: https://cli-assets.heroku.com/heroku-x64.exe
2. İndirilen dosyayı çalıştırın
3. Kurulum tamamlandıktan sonra **PowerShell'i yeniden başlatın**

**Seçenek B: Winget ile**
```powershell
winget install Heroku.HerokuCLI
```

**Seçenek C: Chocolatey ile**
```powershell
choco install heroku-cli
```

### Kurulum Kontrolü

PowerShell'i yeniden başlattıktan sonra:
```powershell
heroku --version
```

Çıktı şöyle olmalı: `heroku/8.x.x win32-x64 node-vX.X.X`

---

## 2. Heroku'ya Giriş

```powershell
heroku login
```

Bu komut bir tarayıcı penceresi açacak. Heroku hesabınızla giriş yapın.

**CLI'den giriş yapmak isterseniz:**
```powershell
heroku login -i
```

---

## 3. Mevcut Repo için Hızlı Başlangıç

Heroku CLI kurulumu tamamlandıktan sonra:

### A. Otomatik Deployment Script (Önerilen)

```powershell
cd C:\Users\mrtko\OneDrive\Ekler\Belgeler\GitHub\dev\yuh
.\scripts\deploy_heroku.ps1 -AppName "sizin-uygulama-adi"
```

Script otomatik olarak:
- ✓ Heroku uygulamasını oluşturacak
- ✓ PostgreSQL addon ekleyecek
- ✓ FLASK_SECRET_KEY oluşturacak
- ✓ Buildpack ayarlayacak
- ✓ Deployment yapacak

### B. Manuel Adımlar

```powershell
# 1. Uygulama oluştur (benzersiz bir isim seçin)
heroku create sizin-uygulama-adi

# 2. Git remote ekle (otomatik eklenir ama kontrol için)
heroku git:remote -a sizin-uygulama-adi

# 3. PostgreSQL addon ekle (ücretli - kredi kartı gerekir)
heroku addons:create heroku-postgresql:essential-0 -a sizin-uygulama-adi

# 4. Flask secret key oluştur ve ayarla
# PowerShell ile rastgele key oluştur:
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$key = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
heroku config:set FLASK_SECRET_KEY=$key -a sizin-uygulama-adi

# 5. Python buildpack ayarla
heroku buildpacks:set heroku/python -a sizin-uygulama-adi

# 6. Değişiklikleri commit et
git add .
git commit -m "Heroku deployment hazırlığı"

# 7. Heroku'ya deploy et
git push heroku yuh:main

# 8. Veritabanı schema'sını oluştur
heroku run python scripts/init_db.py -a sizin-uygulama-adi

# 9. Uygulamayı aç
heroku open -a sizin-uygulama-adi

# 10. Logları takip et
heroku logs --tail -a sizin-uygulama-adi
```

---

## 4. Alternatif: PostgreSQL Olmadan (Ücretsiz)

PostgreSQL addon eklemek istemiyorsanız (ücretli):

```powershell
# 1. Uygulama oluştur
heroku create sizin-uygulama-adi

# 2. Secret key ayarla
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$key = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
heroku config:set FLASK_SECRET_KEY=$key -a sizin-uygulama-adi

# 3. Buildpack
heroku buildpacks:set heroku/python -a sizin-uygulama-adi

# 4. Deploy
git add .
git commit -m "Heroku deployment"
git push heroku yuh:main

# 5. Aç
heroku open -a sizin-uygulama-adi
```

**Not:** PostgreSQL olmadan uygulama SQLite kullanacak, ancak Heroku'nun geçici dosya sistemi nedeniyle her restart'ta veriler silinir. Production için önerilmez.

---

## 5. GitHub Integration (Alternatif Deployment)

Heroku CLI kullanmak istemiyorsanız:

1. https://dashboard.heroku.com/new-app adresine gidin
2. Uygulama adı girin ve "Create app"
3. "Deploy" sekmesine gidin
4. "Deployment method" olarak "GitHub" seçin
5. Repo'nuzu bağlayın: `anonim-01/yuh`
6. Branch seçin: `yuh`
7. "Enable Automatic Deploys" (opsiyonel)
8. "Deploy Branch" butonuna tıklayın

**Ardından Settings'te:**
- Add Buildpack → Python
- Config Vars → Add:
  - `FLASK_SECRET_KEY` = (rastgele 64 karakter)
  - `DATABASE_URL` = (PostgreSQL addon eklerseniz otomatik gelir)

**Resources'ta:**
- Add-ons → Heroku Postgres (opsiyonel, ücretli)

---

## 6. Faydalı Komutlar

```powershell
# Uygulamaları listele
heroku apps

# Mevcut uygulamayı aç
heroku open

# Config değişkenlerini görüntüle
heroku config

# Logs
heroku logs --tail

# Shell
heroku run bash

# Python shell
heroku run python

# Database bağlantısı
heroku pg:psql

# Dyno durumu
heroku ps

# Restart
heroku restart

# Uygulama bilgisi
heroku info
```

---

## 7. Sorun Giderme

### "heroku command not found"
- PowerShell'i yeniden başlatın
- PATH kontrol: `$env:Path -split ';' | Select-String heroku`
- Yeniden yükleyin

### "No app specified"
```powershell
# Remote ekle
heroku git:remote -a uygulama-adi

# VEYA her komutta belirt
heroku logs -a uygulama-adi
```

### "Authentication required"
```powershell
heroku login
# VEYA
heroku login -i
```

### "Insufficient funds" veya "Please verify your account"
- Heroku hesabınıza kredi kartı ekleyin
- https://dashboard.heroku.com/account/billing

---

## 8. Deployment Checklist

- [ ] Heroku CLI kuruldu (`heroku --version`)
- [ ] Heroku'ya giriş yapıldı (`heroku auth:whoami`)
- [ ] Uygulama oluşturuldu (`heroku create`)
- [ ] Git remote eklendi (`git remote -v`)
- [ ] Buildpack ayarlandı (`heroku buildpacks`)
- [ ] FLASK_SECRET_KEY ayarlandı (`heroku config`)
- [ ] PostgreSQL addon eklendi (opsiyonel)
- [ ] Değişiklikler commit edildi (`git status`)
- [ ] Deployment yapıldı (`git push heroku`)
- [ ] Uygulama çalışıyor (`heroku open`)

---

## Yardım

Heroku kurulumu ile ilgili sorun yaşıyorsanız:
- Resmi dokümantasyon: https://devcenter.heroku.com/articles/heroku-cli
- Destek: https://help.heroku.com/

PowerShell yeniden başlatıldıktan sonra `heroku --version` çalışmalı!
