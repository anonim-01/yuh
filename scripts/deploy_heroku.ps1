# Heroku Deployment Script - PowerShell Version
param(
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Heroku Deployment Kontrol Scripti" -ForegroundColor Cyan
Write-Host "Uygulama: $AppName" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Heroku CLI kontrolü
try {
    $null = Get-Command heroku -ErrorAction Stop
    Write-Host "✓ Heroku CLI yüklü" -ForegroundColor Green
} catch {
    Write-Host "❌ Heroku CLI bulunamadı!" -ForegroundColor Red
    Write-Host "Lütfen yükleyin: https://devcenter.heroku.com/articles/heroku-cli" -ForegroundColor Yellow
    exit 1
}

# Git kontrolü
try {
    $null = Get-Command git -ErrorAction Stop
    Write-Host "✓ Git yüklü" -ForegroundColor Green
} catch {
    Write-Host "❌ Git bulunamadı!" -ForegroundColor Red
    exit 1
}

# Heroku login kontrolü
try {
    $null = heroku auth:whoami 2>$null
    Write-Host "✓ Heroku oturumu aktif" -ForegroundColor Green
} catch {
    Write-Host "❌ Heroku'ya giriş yapılmamış!" -ForegroundColor Red
    Write-Host "Lütfen giriş yapın: heroku login" -ForegroundColor Yellow
    exit 1
}

# Uygulama varlık kontrolü
try {
    $null = heroku apps:info -a $AppName 2>$null
    Write-Host "✓ Uygulama mevcut" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "⚠️  Uygulama '$AppName' bulunamadı!" -ForegroundColor Yellow
    $response = Read-Host "Yeni uygulama oluşturulsun mu? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        heroku create $AppName
        Write-Host "✓ Uygulama oluşturuldu" -ForegroundColor Green
    } else {
        Write-Host "İptal edildi." -ForegroundColor Yellow
        exit 1
    }
}

# Git remote kontrolü
$remotes = git remote
if ($remotes -notcontains "heroku") {
    Write-Host "⚠️  Heroku git remote bulunamadı, ekleniyor..." -ForegroundColor Yellow
    heroku git:remote -a $AppName
    Write-Host "✓ Git remote eklendi" -ForegroundColor Green
} else {
    Write-Host "✓ Heroku git remote mevcut" -ForegroundColor Green
}

# PostgreSQL addon kontrolü
Write-Host ""
Write-Host "PostgreSQL addon kontrol ediliyor..." -ForegroundColor Cyan
$addons = heroku addons -a $AppName 2>$null | Out-String
if ($addons -notmatch "heroku-postgresql") {
    Write-Host "⚠️  PostgreSQL addon bulunamadı!" -ForegroundColor Yellow
    $response = Read-Host "PostgreSQL addon eklensin mi? (essential-0 planı, ücretli) (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        heroku addons:create heroku-postgresql:essential-0 -a $AppName
        Write-Host "✓ PostgreSQL addon eklendi" -ForegroundColor Green
        Write-Host "⏳ Addon başlatılıyor (1-2 dakika)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } else {
        Write-Host "⚠️  PostgreSQL olmadan devam ediliyor (SQLite kullanılacak)" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ PostgreSQL addon mevcut" -ForegroundColor Green
}

# Ortam değişkenleri kontrolü
Write-Host ""
Write-Host "Ortam değişkenleri kontrol ediliyor..." -ForegroundColor Cyan

$secretKey = heroku config:get FLASK_SECRET_KEY -a $AppName 2>$null
if ([string]::IsNullOrWhiteSpace($secretKey)) {
    Write-Host "⚠️  FLASK_SECRET_KEY tanımlı değil!" -ForegroundColor Yellow
    $response = Read-Host "Otomatik rastgele anahtar oluşturulsun mu? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        # PowerShell'de rastgele anahtar oluştur
        $bytes = New-Object byte[] 32
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $secretKey = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
        heroku config:set FLASK_SECRET_KEY=$secretKey -a $AppName
        Write-Host "✓ FLASK_SECRET_KEY ayarlandı" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Manuel olarak ayarlamanız gerekiyor:" -ForegroundColor Yellow
        Write-Host "   heroku config:set FLASK_SECRET_KEY='YOUR_SECRET_KEY' -a $AppName" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ FLASK_SECRET_KEY tanımlı" -ForegroundColor Green
}

# Buildpack kontrolü
Write-Host ""
Write-Host "Buildpack kontrol ediliyor..." -ForegroundColor Cyan
$buildpacks = heroku buildpacks -a $AppName 2>$null | Out-String
if ($buildpacks -notmatch "heroku/python") {
    Write-Host "⚠️  Python buildpack bulunamadı, ayarlanıyor..." -ForegroundColor Yellow
    heroku buildpacks:clear -a $AppName
    heroku buildpacks:set heroku/python -a $AppName
    Write-Host "✓ Python buildpack ayarlandı" -ForegroundColor Green
} else {
    Write-Host "✓ Python buildpack mevcut" -ForegroundColor Green
}

# Deployment
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Hazır! Deployment başlatılıyor..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Git durumu
$branch = git branch --show-current
Write-Host "Mevcut branch: $branch" -ForegroundColor White
Write-Host ""

$response = Read-Host "Deployment başlatılsın mı? (y/n)"
if ($response -ne 'y' -and $response -ne 'Y') {
    Write-Host "İptal edildi." -ForegroundColor Yellow
    exit 0
}

# Deployment
Write-Host ""
Write-Host "🚀 Deployment başlatılıyor..." -ForegroundColor Green
git push heroku "${branch}:main"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ Deployment tamamlandı!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Deployment sonrası
Write-Host "Uygulama bilgileri:" -ForegroundColor Cyan
heroku info -a $AppName

Write-Host ""
Write-Host "Uygulama açılıyor..." -ForegroundColor Cyan
heroku open -a $AppName

Write-Host ""
Write-Host "Logları görüntülemek için:" -ForegroundColor Yellow
Write-Host "  heroku logs --tail -a $AppName" -ForegroundColor White
Write-Host ""
Write-Host "Veritabanı schema'sını başlatmak için:" -ForegroundColor Yellow
Write-Host "  heroku run python scripts/init_db.py -a $AppName" -ForegroundColor White
