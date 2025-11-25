# Environment Variables Rehberi

Bu dosya, projedeki ortam değişkenlerinin nasıl yapılandırılacağını açıklar.

## 📁 Dosya Yapısı

- **`.env.example`** - Şablon dosya (commit edilir, GitHub'da görünür)
- **`.env`** - Gerçek yapılandırma (commit edilmez, sadece yerel)

## 🚀 Hızlı Başlangıç

### 1. Yerel Geliştirme İçin .env Oluştur

```powershell
# .env.example dosyasını kopyala
Copy-Item .env.example .env

# VEYA zaten oluşturulmuş .env dosyası var, düzenle:
notepad .env
```

### 2. FLASK_SECRET_KEY Oluştur

Güvenli bir secret key oluşturmak için:

**PowerShell:**
```powershell
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$key = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
Write-Host $key
```

**Bash/Mac/Linux:**
```bash
openssl rand -hex 32
```

Çıkan değeri `.env` dosyasında `FLASK_SECRET_KEY` olarak kullanın.

### 3. Uygulamayı Çalıştır

```powershell
# Virtual environment oluştur (ilk kez)
python -m venv venv

# Aktif et
.\venv\Scripts\Activate.ps1

# Bağımlılıkları yükle
pip install -r requirements.txt

# Uygulamayı çalıştır
python main.py
```

Uygulama http://localhost:5000 adresinde çalışacak.

---

## 📋 Environment Variables Açıklamaları

### Flask Configuration

| Değişken | Açıklama | Varsayılan | Örnek |
|----------|----------|-----------|-------|
| `FLASK_SECRET_KEY` | Session encryption anahtarı | **(ZORUNLU)** | `a1b2c3d4...` (64 karakter) |
| `FLASK_ENV` | Ortam modu | `production` | `development`, `production` |
| `FLASK_DEBUG` | Debug mode | `false` | `true`, `false` |

### Database Configuration

| Değişken | Açıklama | Varsayılan | Örnek |
|----------|----------|-----------|-------|
| `DATABASE_URL` | Veritabanı bağlantı URL'i | SQLite (`db.sqlite3`) | `postgresql://user:pass@host:5432/db` |

**Notlar:**
- `DATABASE_URL` boşsa SQLite kullanılır (yerel geliştirme için ideal)
- PostgreSQL için tam connection string gereklidir
- Heroku otomatik olarak `DATABASE_URL` ayarlar

### Application Settings

| Değişken | Açıklama | Varsayılan | Örnek |
|----------|----------|-----------|-------|
| `FRONTEND_ENCRYPTION_ENABLED` | Frontend şifreleme | `true` | `true`, `false` |
| `WEB_CONCURRENCY` | Gunicorn worker sayısı | `2` | `2`, `4`, `8` |
| `LOG_LEVEL` | Log seviyesi | `info` | `debug`, `info`, `warning`, `error` |

### Heroku Configuration (Opsiyonel)

| Değişken | Açıklama | Örnek |
|----------|----------|-------|
| `HEROKU_APP_NAME` | Uygulama adı | `my-app` |
| `HEROKU_BRANCH` | Deploy branch | `main`, `yuh` |
| `HEROKU_PR_NUMBER` | PR numarası (review apps) | `123` |

### Cloudflare Configuration (Opsiyonel)

| Değişken | Açıklama |
|----------|----------|
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare hesap ID |
| `CLOUDFLARE_API_TOKEN` | API token |
| `CLOUDFLARE_AUTH_EMAIL` | Hesap email |
| `CLOUDFLARE_AUTH_KEY` | API key |
| `CLOUDFLARE_ZONE_ID` | Zone ID |
| `CLOUDFLARE_SSL_HOSTS` | SSL hosts (virgülle ayır) |

---

## 🔧 Ortam Bazlı Yapılandırma

### Yerel Geliştirme (.env)
```bash
FLASK_SECRET_KEY=local-dev-key-32-chars-long
FLASK_ENV=development
FLASK_DEBUG=true
DATABASE_URL=
LOG_LEVEL=debug
```

### Production (Heroku Config Vars)
```bash
FLASK_SECRET_KEY=<güvenli-rastgele-64-karakter>
FLASK_ENV=production
FLASK_DEBUG=false
DATABASE_URL=<heroku-postgres-url>
LOG_LEVEL=info
WEB_CONCURRENCY=4
```

---

## ⚠️ Güvenlik Notları

### ❌ YAPMAYIN
- `.env` dosyasını commit etmeyin
- Secret key'leri GitHub'a yüklemeyin
- Aynı secret key'i farklı ortamlarda kullanmayın
- Production secret key'i kod içine yazmayın

### ✅ YAPIN
- Her ortam için farklı secret key kullanın
- `.env.example` dosyasını güncel tutun (ama gerçek değerler olmadan)
- Secret key'leri güvenli yerlerde saklayın (password manager, vault)
- Production için Heroku Config Vars kullanın
- Secret key'leri düzenli olarak yenileyin

---

## 🐛 Sorun Giderme

### "SECRET_KEY is not set" Hatası
```powershell
# .env dosyası var mı kontrol et
Get-Item .env

# .env içeriğini kontrol et
Get-Content .env

# Yoksa oluştur
Copy-Item .env.example .env
```

### ".env dosyası yüklenmiyor"
```python
# main.py veya app/__init__.py içinde kontrol et
from dotenv import load_dotenv
load_dotenv()  # .env dosyasını yükler

import os
print(os.getenv('FLASK_SECRET_KEY'))  # Test için
```

### "Database connection error"
```bash
# SQLite kullanmak için DATABASE_URL'i boş bırakın
DATABASE_URL=

# VEYA açıkça belirtin
DATABASE_URL=sqlite:///db.sqlite3
```

---

## 📚 Ek Kaynaklar

- [Flask Configuration](https://flask.palletsprojects.com/en/3.0.x/config/)
- [python-dotenv Docs](https://pypi.org/project/python-dotenv/)
- [Heroku Config Vars](https://devcenter.heroku.com/articles/config-vars)
- [12 Factor App - Config](https://12factor.net/config)

---

## 🔄 .env Değişikliklerini Uygulama

`.env` dosyasını değiştirdikten sonra:

```powershell
# Development server'ı yeniden başlat
# Ctrl+C ile durdur, sonra tekrar:
python main.py

# VEYA Gunicorn ile
gunicorn main:app --reload
```

Heroku'da config var değişikliği otomatik olarak dyno'ları yeniden başlatır.
