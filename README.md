# Flask Kart İşleme Uygulaması

Minimal Flask uygulamamız, PostgreSQL desteğini Heroku üzerinde çalışacak şekilde yapılandırılmıştır.

## Heroku Ortamı

- `runtime.txt`: Python 3.11.5 kullanır
- `requirements.txt`: Gunicorn, psycopg[binary] ve diğer üretim bağımlılıkları
- `Procfile`: `scripts/heroku_start.sh` üzerinden `gunicorn main:app` çalıştırır
- `app.json`: Heroku otomatik yapılandırması (PostgreSQL addon dahil)
- Veritabanı: Heroku Postgres (opsiyonel SQLite fallback)

## Heroku'ya İlk Deployment

### 1. Heroku Uygulaması Oluştur

```bash
# Heroku CLI ile yeni uygulama oluştur
heroku create <uygulama-adi>

# VEYA mevcut repoyu Heroku'ya bağla
heroku git:remote -a <mevcut-uygulama-adi>
```

### 2. PostgreSQL Addon Ekle

```bash
# Heroku Postgres eklentisini yükle (app.json otomatik ekler veya manuel)
heroku addons:create heroku-postgresql:essential-0 -a <uygulama-adi>

# DATABASE_URL otomatik olarak ayarlanacak
heroku config -a <uygulama-adi>
```

### 3. Ortam Değişkenlerini Ayarla

```bash
# Gerekli: Flask gizli anahtarı (rastgele güvenli değer)
heroku config:set FLASK_SECRET_KEY="$(openssl rand -hex 32)" -a <uygulama-adi>

# Opsiyonel: Frontend şifreleme
heroku config:set FRONTEND_ENCRYPTION_ENABLED=true -a <uygulama-adi>

# Opsiyonel: Cloudflare ayarları
heroku config:set CLOUDFLARE_ACCOUNT_ID="your-account-id" -a <uygulama-adi>
heroku config:set CLOUDFLARE_API_TOKEN="your-api-token" -a <uygulama-adi>
heroku config:set CLOUDFLARE_ZONE_ID="your-zone-id" -a <uygulama-adi>

# Gunicorn worker sayısı (varsayılan: 2)
heroku config:set WEB_CONCURRENCY=4 -a <uygulama-adi>
```

### 4. Buildpack'i Ayarla

```bash
# Python buildpack'inin doğru şekilde ayarlandığından emin ol
heroku buildpacks:clear -a <uygulama-adi>
heroku buildpacks:set heroku/python -a <uygulama-adi>
```

### 5. Deployment

```bash
# Değişiklikleri commit et
git add .
git commit -m "Heroku deployment hazırlığı"

# Heroku'ya push et
git push heroku main

# VEYA başka branch kullanıyorsan
git push heroku yuh:main
```

### 6. Deployment Sonrası

```bash
# Logları takip et
heroku logs --tail -a <uygulama-adi>

# Uygulama durumunu kontrol et
heroku ps -a <uygulama-adi>

# Web tarayıcıda aç
heroku open -a <uygulama-adi>

# PostgreSQL bağlantısını test et
heroku run python scripts/init_db.py -a <uygulama-adi>
```

## Yerel Geliştirme

```bash
# Virtual environment oluştur
python -m venv venv

# Windows PowerShell
.\venv\Scripts\Activate.ps1

# Linux/Mac
source venv/bin/activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# .env dosyası oluştur
echo "FLASK_SECRET_KEY=dev-secret-key" > .env
echo "FRONTEND_ENCRYPTION_ENABLED=true" >> .env

# Uygulamayı çalıştır (SQLite modunda)
python main.py
```

Uygulama http://localhost:5000 adresinde çalışacaktır.

## Veritabanı Geçişi (SQLite → PostgreSQL)

```bash
# 1. SQLite'tan SQL dump oluştur
python full_dump_sqlite_to_postgres.py

# 2. PostgreSQL'e import et (Heroku'da)
heroku run python import_data.py -a <uygulama-adi>

# VEYA yerel PostgreSQL'de test et
python import_data.py
```

## Önemli Notlar

- **Güvenlik**: `FLASK_SECRET_KEY` mutlaka güçlü ve rastgele bir değer olmalı
- **Veritabanı**: PostgreSQL şiddetle tavsiye edilir, SQLite sadece development için
- **Loglar**: `heroku logs --tail` ile real-time takip yapılabilir
- **Scale**: `heroku ps:scale web=2` ile dyno sayısı artırılabilir
- **Schema**: İlk deployment'ta tablolar otomatik oluşturulur (`app/database.py`)
- **Cloudflare**: Opsiyonel, DNS/SSL/Tunnel özellikleri için gerekli

## Sorun Giderme

### Build Hatası
```bash
# Buildpack listesini kontrol et
heroku buildpacks -a <uygulama-adi>

# Yalnızca Python olmalı
heroku buildpacks:clear -a <uygulama-adi>
heroku buildpacks:set heroku/python -a <uygulama-adi>
```

### Database Bağlantı Hatası
```bash
# DATABASE_URL'i kontrol et
heroku config:get DATABASE_URL -a <uygulama-adi>

# Postgres addon durumunu kontrol et
heroku addons:info heroku-postgresql -a <uygulama-adi>
```

### Application Error (H10)
```bash
# Dyno'lar çalışıyor mu?
heroku ps -a <uygulama-adi>

# Web dyno'yu restart et
heroku restart -a <uygulama-adi>

# Detaylı logları incele
heroku logs --tail -a <uygulama-adi>
```

## Daha Fazla Bilgi

- [Heroku Python Docs](https://devcenter.heroku.com/categories/python-support)
- [Heroku Postgres](https://devcenter.heroku.com/articles/heroku-postgresql)
- [Flask Production Guide](https://flask.palletsprojects.com/en/3.0.x/deploying/)