# Heroku Config Vars - Tek Komut

Bu dosya, Heroku'da gerekli tüm config vars'ları tek komutta ayarlamanız için hazırlanmıştır.

## 🚀 Hızlı Kullanım

### Seçenek 1: Etkileşimli Script (Önerilen)
```powershell
.\scripts\set_heroku_config.ps1 -AppName "your-app-name"
```

Script size her değişken için soru soracak ve uygun değerleri ayarlayacak.

### Seçenek 2: Hızlı Script (Varsayılan Değerlerle)
```powershell
.\scripts\set_heroku_config_quick.ps1 -AppName "your-app-name"
```

Tüm değişkenler varsayılan değerlerle otomatik ayarlanır.

### Seçenek 3: Tek Satır Komut (Manuel)
```powershell
# Uygulama adınızı değiştirin!
$APP = "your-app-name"

# FLASK_SECRET_KEY oluştur
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$key = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()

# Tüm config vars'ı ayarla
heroku config:set `
    FLASK_SECRET_KEY="$key" `
    FRONTEND_ENCRYPTION_ENABLED="true" `
    WEB_CONCURRENCY="2" `
    LOG_LEVEL="info" `
    HEROKU_APP_NAME="$APP" `
    HEROKU_BRANCH="main" `
    -a $APP
```

---

## 📋 Config Vars Listesi

| Değişken | Açıklama | Varsayılan | Zorunlu |
|----------|----------|-----------|---------|
| `FLASK_SECRET_KEY` | Flask session encryption key | (otomatik) | ✅ Evet |
| `FRONTEND_ENCRYPTION_ENABLED` | Frontend şifreleme | `true` | ❌ Hayır |
| `WEB_CONCURRENCY` | Gunicorn worker sayısı | `2` | ❌ Hayır |
| `LOG_LEVEL` | Log seviyesi | `info` | ❌ Hayır |
| `HEROKU_APP_NAME` | Uygulama adı | (app name) | ❌ Hayır |
| `HEROKU_BRANCH` | Deploy branch | `main` | ❌ Hayır |
| `HEROKU_PR_NUMBER` | PR numarası (review apps) | - | ❌ Hayır |
| `DATABASE_URL` | PostgreSQL URL | (auto) | ❌ Hayır |

### Opsiyonel: Cloudflare
| Değişken | Açıklama |
|----------|----------|
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare hesap ID |
| `CLOUDFLARE_API_TOKEN` | API token |
| `CLOUDFLARE_AUTH_EMAIL` | Hesap email |
| `CLOUDFLARE_AUTH_KEY` | API key |
| `CLOUDFLARE_ZONE_ID` | Zone ID |
| `CLOUDFLARE_SSL_HOSTS` | SSL hosts (virgülle ayırın) |

---

## 🔧 Manuel Komutlar

Her değişkeni ayrı ayrı ayarlamak için:

```powershell
$APP = "your-app-name"

# 1. FLASK_SECRET_KEY (ZORUNLU)
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$key = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
heroku config:set FLASK_SECRET_KEY="$key" -a $APP

# 2. FRONTEND_ENCRYPTION_ENABLED
heroku config:set FRONTEND_ENCRYPTION_ENABLED="true" -a $APP

# 3. WEB_CONCURRENCY
heroku config:set WEB_CONCURRENCY="2" -a $APP

# 4. LOG_LEVEL
heroku config:set LOG_LEVEL="info" -a $APP

# 5. HEROKU_APP_NAME
heroku config:set HEROKU_APP_NAME="$APP" -a $APP

# 6. HEROKU_BRANCH
heroku config:set HEROKU_BRANCH="main" -a $APP

# 7. HEROKU_PR_NUMBER (opsiyonel)
heroku config:set HEROKU_PR_NUMBER="123" -a $APP
```

---

## ✅ Kontrol

Config vars'ların doğru ayarlandığını kontrol edin:

```powershell
# Tüm config vars'ları göster
heroku config -a your-app-name

# Belirli bir değişkeni göster
heroku config:get FLASK_SECRET_KEY -a your-app-name

# JSON formatında
heroku config -a your-app-name --json
```

---

## 🗑️ Silme

Bir config var'ı silmek için:

```powershell
heroku config:unset VARIABLE_NAME -a your-app-name

# Örnek
heroku config:unset HEROKU_PR_NUMBER -a your-app-name
```

---

## 📝 .env Dosyası (Yerel Geliştirme)

Yerel geliştirme için `.env` dosyası oluşturun:

```bash
FLASK_SECRET_KEY=dev-secret-key-local
FRONTEND_ENCRYPTION_ENABLED=true
WEB_CONCURRENCY=2
LOG_LEVEL=debug
DATABASE_URL=sqlite:///db.sqlite3

# Cloudflare (opsiyonel)
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_API_TOKEN=your-token
CLOUDFLARE_ZONE_ID=your-zone-id
```

**Not:** `.env` dosyası `.gitignore`'da olmalı (zaten ekli).

---

## 🔐 Güvenlik Notları

- ❌ `FLASK_SECRET_KEY` asla GitHub'a commit edilmemeli
- ✅ Her ortam (dev, staging, prod) için farklı key kullanın
- ✅ En az 32 karakter rastgele değer kullanın
- ❌ Cloudflare API anahtarlarını paylaşmayın
- ✅ Review apps için ayrı Cloudflare ayarları kullanın

---

## 📚 Kaynaklar

- [Heroku Config Vars Docs](https://devcenter.heroku.com/articles/config-vars)
- [Flask Secret Key](https://flask.palletsprojects.com/en/3.0.x/config/#SECRET_KEY)
- [Gunicorn Workers](https://docs.gunicorn.org/en/stable/settings.html#workers)
