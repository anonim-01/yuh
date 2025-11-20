#!/usr/bin/env bash
# Heroku deployment kontrol ve yardımcı script

set -e

APP_NAME="${1:-}"

if [ -z "$APP_NAME" ]; then
    echo "Kullanım: ./deploy_heroku.sh <heroku-app-name>"
    echo ""
    echo "Örnek: ./deploy_heroku.sh my-flask-app"
    exit 1
fi

echo "======================================"
echo "Heroku Deployment Kontrol Scripti"
echo "Uygulama: $APP_NAME"
echo "======================================"
echo ""

# Heroku CLI kontrolü
if ! command -v heroku &> /dev/null; then
    echo "❌ Heroku CLI bulunamadı!"
    echo "Lütfen yükleyin: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
fi
echo "✓ Heroku CLI yüklü"

# Git kontrolü
if ! command -v git &> /dev/null; then
    echo "❌ Git bulunamadı!"
    exit 1
fi
echo "✓ Git yüklü"

# Heroku login kontrolü
if ! heroku auth:whoami &> /dev/null; then
    echo "❌ Heroku'ya giriş yapılmamış!"
    echo "Lütfen giriş yapın: heroku login"
    exit 1
fi
echo "✓ Heroku oturumu aktif"

# Uygulama varlık kontrolü
if ! heroku apps:info -a "$APP_NAME" &> /dev/null; then
    echo ""
    echo "⚠️  Uygulama '$APP_NAME' bulunamadı!"
    read -p "Yeni uygulama oluşturulsun mu? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        heroku create "$APP_NAME"
        echo "✓ Uygulama oluşturuldu"
    else
        echo "İptal edildi."
        exit 1
    fi
else
    echo "✓ Uygulama mevcut"
fi

# Git remote kontrolü
if ! git remote | grep -q "^heroku$"; then
    echo "⚠️  Heroku git remote bulunamadı, ekleniyor..."
    heroku git:remote -a "$APP_NAME"
    echo "✓ Git remote eklendi"
else
    echo "✓ Heroku git remote mevcut"
fi

# PostgreSQL addon kontrolü
echo ""
echo "PostgreSQL addon kontrol ediliyor..."
if ! heroku addons -a "$APP_NAME" | grep -q "heroku-postgresql"; then
    echo "⚠️  PostgreSQL addon bulunamadı!"
    read -p "PostgreSQL addon eklensin mi? (essential-0 planı, ücretli) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        heroku addons:create heroku-postgresql:essential-0 -a "$APP_NAME"
        echo "✓ PostgreSQL addon eklendi"
        echo "⏳ Addon başlatılıyor (1-2 dakika)..."
        sleep 5
    else
        echo "⚠️  PostgreSQL olmadan devam ediliyor (SQLite kullanılacak)"
    fi
else
    echo "✓ PostgreSQL addon mevcut"
fi

# Ortam değişkenleri kontrolü
echo ""
echo "Ortam değişkenleri kontrol ediliyor..."

if ! heroku config:get FLASK_SECRET_KEY -a "$APP_NAME" &> /dev/null || [ -z "$(heroku config:get FLASK_SECRET_KEY -a "$APP_NAME")" ]; then
    echo "⚠️  FLASK_SECRET_KEY tanımlı değil!"
    read -p "Otomatik rastgele anahtar oluşturulsun mu? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SECRET_KEY=$(openssl rand -hex 32)
        heroku config:set FLASK_SECRET_KEY="$SECRET_KEY" -a "$APP_NAME"
        echo "✓ FLASK_SECRET_KEY ayarlandı"
    else
        echo "⚠️  Manuel olarak ayarlamanız gerekiyor:"
        echo "   heroku config:set FLASK_SECRET_KEY='YOUR_SECRET_KEY' -a $APP_NAME"
    fi
else
    echo "✓ FLASK_SECRET_KEY tanımlı"
fi

# Buildpack kontrolü
echo ""
echo "Buildpack kontrol ediliyor..."
BUILDPACK=$(heroku buildpacks -a "$APP_NAME" | grep heroku/python || true)
if [ -z "$BUILDPACK" ]; then
    echo "⚠️  Python buildpack bulunamadı, ayarlanıyor..."
    heroku buildpacks:clear -a "$APP_NAME"
    heroku buildpacks:set heroku/python -a "$APP_NAME"
    echo "✓ Python buildpack ayarlandı"
else
    echo "✓ Python buildpack mevcut"
fi

# Deployment
echo ""
echo "======================================"
echo "Hazır! Deployment başlatılıyor..."
echo "======================================"
echo ""

# Git durumu
BRANCH=$(git branch --show-current)
echo "Mevcut branch: $BRANCH"
echo ""

read -p "Deployment başlatılsın mı? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "İptal edildi."
    exit 0
fi

# Deployment
echo ""
echo "🚀 Deployment başlatılıyor..."
git push heroku "$BRANCH:main"

echo ""
echo "======================================"
echo "✓ Deployment tamamlandı!"
echo "======================================"
echo ""

# Deployment sonrası
echo "Uygulama bilgileri:"
heroku info -a "$APP_NAME"

echo ""
echo "Uygulama açılıyor..."
heroku open -a "$APP_NAME"

echo ""
echo "Logları görüntülemek için:"
echo "  heroku logs --tail -a $APP_NAME"
echo ""
echo "Veritabanı schema'sını başlatmak için:"
echo "  heroku run python scripts/init_db.py -a $APP_NAME"
