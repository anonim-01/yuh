# Heroku Deployment Rehberi

Bu rehber, Flask uygulamanızı Heroku'ya deploy etmek için adım adım talimatlar içerir.

## Hızlı Başlangıç

### Otomatik Deployment (Önerilen)

**Windows (PowerShell):**
```powershell
.\scripts\deploy_heroku.ps1 -AppName "uygulama-adi"
```

**Linux/Mac (Bash):**
```bash
chmod +x scripts/deploy_heroku.sh
./scripts/deploy_heroku.sh uygulama-adi
```

Bu script otomatik olarak:
- ✓ Gerekli araçları kontrol eder
- ✓ Heroku uygulamasını oluşturur (eğer yoksa)
- ✓ PostgreSQL addon ekler (opsiyonel)
- ✓ FLASK_SECRET_KEY oluşturur
- ✓ Buildpack ayarlar
- ✓ Deployment yapar

---

## Manuel Deployment

### 1. Ön Gereksinimler

```bash
# Heroku CLI yükleyin
# Windows: https://devcenter.heroku.com/articles/heroku-cli
# Mac: brew install heroku/brew/heroku
# Linux: curl https://cli-assets.heroku.com/install.sh | sh

# Heroku'ya giriş yapın
heroku login

# Git ile Heroku'yu bağlayın
heroku create uygulama-adi
heroku git:remote -a uygulama-adi
```

### 2. PostgreSQL Addon

```bash
# PostgreSQL addon ekle (ücretli plan)
heroku addons:create heroku-postgresql:essential-0 -a uygulama-adi

# Addon durumunu kontrol et
heroku addons:info heroku-postgresql -a uygulama-adi

# DATABASE_URL otomatik ayarlandı mı kontrol et
heroku config:get DATABASE_URL -a uygulama-adi
```

**Not:** PostgreSQL eklemezseniz uygulama SQLite ile çalışır (production için önerilmez).

### 3. Ortam Değişkenleri

```bash
# ZORUNLU: Flask gizli anahtarı
heroku config:set FLASK_SECRET_KEY="$(openssl rand -hex 32)" -a uygulama-adi

# Windows PowerShell için:
$key = -join ((48..57) + (97..102) | Get-Random -Count 64 | % {[char]$_})
heroku config:set FLASK_SECRET_KEY="$key" -a uygulama-adi

# OPSIYONEL: Diğer ayarlar
heroku config:set FRONTEND_ENCRYPTION_ENABLED=true -a uygulama-adi
heroku config:set WEB_CONCURRENCY=4 -a uygulama-adi
heroku config:set LOG_LEVEL=info -a uygulama-adi

# Cloudflare ayarları (opsiyonel)
heroku config:set CLOUDFLARE_ACCOUNT_ID="your-id" -a uygulama-adi
heroku config:set CLOUDFLARE_API_TOKEN="your-token" -a uygulama-adi
heroku config:set CLOUDFLARE_ZONE_ID="your-zone-id" -a uygulama-adi
```

### 4. Buildpack Ayarları

```bash
# Buildpack'leri temizle
heroku buildpacks:clear -a uygulama-adi

# Sadece Python buildpack ekle
heroku buildpacks:set heroku/python -a uygulama-adi

# Kontrol et
heroku buildpacks -a uygulama-adi
```

### 5. Deployment

```bash
# Değişiklikleri commit et
git add .
git commit -m "Heroku deployment"

# Heroku'ya push et
git push heroku main

# VEYA farklı branch kullanıyorsanız
git push heroku your-branch:main
```

### 6. Deployment Sonrası

```bash
# Uygulama durumunu kontrol et
heroku ps -a uygulama-adi

# Logları izle
heroku logs --tail -a uygulama-adi

# Veritabanı schema'sını başlat
heroku run python scripts/init_db.py -a uygulama-adi

# Web tarayıcıda aç
heroku open -a uygulama-adi
```

---

## Konfigürasyon Dosyaları

Deployment için gerekli dosyalar hazır:

| Dosya | Açıklama |
|-------|----------|
| `runtime.txt` | Python 3.11.5 sürümünü belirtir |
| `requirements.txt` | Python bağımlılıkları |
| `Procfile` | Heroku process tanımı |
| `app.json` | Heroku uygulama manifesti |
| `scripts/heroku_start.sh` | Gunicorn başlatma scripti |
| `.gitignore` | Git ignore kuralları |

---

## Sorun Giderme

### Build Hatası: "Failed to detect set buildpack"

```bash
heroku buildpacks:clear -a uygulama-adi
heroku buildpacks:set heroku/python -a uygulama-adi
git push heroku main
```

### Application Error (H10)

```bash
# Dynolar çalışıyor mu?
heroku ps -a uygulama-adi

# Restart
heroku restart -a uygulama-adi

# Logları kontrol et
heroku logs --tail -a uygulama-adi
```

### Database Connection Error

```bash
# DATABASE_URL var mı?
heroku config -a uygulama-adi

# PostgreSQL addon durumu
heroku addons:info heroku-postgresql -a uygulama-adi

# Schema oluştur
heroku run python scripts/init_db.py -a uygulama-adi
```

### Timeout Error (H12)

```bash
# Worker timeout artır
heroku config:set TIMEOUT=120 -a uygulama-adi

# Worker sayısını azalt (memory yetersizse)
heroku config:set WEB_CONCURRENCY=2 -a uygulama-adi
```

### Slug Size Too Large

```bash
# Cache temizle
heroku repo:purge_cache -a uygulama-adi

# Gereksiz dosyaları .gitignore'a ekle
echo "*.pyc" >> .gitignore
echo "__pycache__/" >> .gitignore
git add .gitignore
git commit -m "Update gitignore"
git push heroku main
```

---

## Veritabanı İşlemleri

### SQLite'tan PostgreSQL'e Geçiş

```bash
# 1. Yerel SQLite'tan dump al
python full_dump_sqlite_to_postgres.py

# 2. Heroku'ya import et
heroku run python import_data.py -a uygulama-adi

# 3. Kontrol et
heroku run python -c "from app.database import fetch_all; print(fetch_all('SELECT COUNT(*) FROM sazan'))" -a uygulama-adi
```

### Backup Alma

```bash
# Manuel backup
heroku pg:backups:capture -a uygulama-adi

# Backup listesi
heroku pg:backups -a uygulama-adi

# Backup indirme
heroku pg:backups:download -a uygulama-adi
```

### Database Reset (DİKKAT!)

```bash
# TÜM VERİLER SİLİNİR!
heroku pg:reset DATABASE -a uygulama-adi --confirm uygulama-adi

# Schema'yı yeniden oluştur
heroku run python scripts/init_db.py -a uygulama-adi
```

---

## Scaling & Performance

### Dyno Scaling

```bash
# Web dyno sayısını artır
heroku ps:scale web=2 -a uygulama-adi

# Worker sayısını artır (her dyno için)
heroku config:set WEB_CONCURRENCY=4 -a uygulama-adi
```

### Database Plan Upgrade

```bash
# Mevcut plan
heroku addons:info heroku-postgresql -a uygulama-adi

# Plan upgrade (daha fazla bağlantı/storage)
heroku addons:upgrade heroku-postgresql:standard-0 -a uygulama-adi
```

### Log Management

```bash
# Real-time loglar
heroku logs --tail -a uygulama-adi

# Son 500 satır
heroku logs -n 500 -a uygulama-adi

# Sadece uygulama logları
heroku logs --source app -a uygulama-adi

# Sadece dyno logları
heroku logs --dyno web -a uygulama-adi
```

---

## Güvenlik Kontrol Listesi

- [ ] `FLASK_SECRET_KEY` güçlü ve rastgele
- [ ] SQLite yerine PostgreSQL kullanılıyor
- [ ] `.env` dosyası `.gitignore`'da
- [ ] `db.sqlite3` dosyası commit edilmemiş
- [ ] Cloudflare API tokenları gizli
- [ ] Production'da `DEBUG=False`
- [ ] HTTPS/SSL aktif (Heroku otomatik)
- [ ] Rate limiting aktif (`app/ip_blocker.py`)
- [ ] Hassas veriler şifreli (`app/encryption.py`)

---

## Faydalı Komutlar

```bash
# Uygulama bilgileri
heroku info -a uygulama-adi

# Tüm config değişkenleri
heroku config -a uygulama-adi

# Shell açma
heroku run bash -a uygulama-adi

# Python shell
heroku run python -a uygulama-adi

# Dosya sistemi kontrol
heroku run ls -la -a uygulama-adi

# Database console
heroku pg:psql -a uygulama-adi
```

---

## Ek Kaynaklar

- [Heroku Python Docs](https://devcenter.heroku.com/categories/python-support)
- [Heroku Postgres](https://devcenter.heroku.com/articles/heroku-postgresql)
- [Gunicorn Configuration](https://docs.gunicorn.org/en/stable/settings.html)
- [Flask Deployment](https://flask.palletsprojects.com/en/3.0.x/deploying/)

---

## Yardım

Sorun yaşıyorsanız:

1. `heroku logs --tail -a uygulama-adi` ile logları kontrol edin
2. `heroku ps -a uygulama-adi` ile dyno durumunu kontrol edin
3. `heroku config -a uygulama-adi` ile ortam değişkenlerini kontrol edin
4. GitHub Issues'da sorun bildirin
