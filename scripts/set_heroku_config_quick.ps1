# Heroku Config Vars - Hızlı Ayarlama (Etkileşimsiz)
# Tüm değişkenleri varsayılan değerlerle ayarlar

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,
    
    [string]$WebConcurrency = "2",
    [string]$LogLevel = "info",
    [string]$Branch = "main"
)

Write-Host "🚀 Heroku Config Vars ayarlanıyor: $AppName" -ForegroundColor Cyan

# FLASK_SECRET_KEY - otomatik oluştur
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$secretKey = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()

# Tüm config vars'ı tek komutta ayarla
heroku config:set `
    FLASK_SECRET_KEY="$secretKey" `
    FRONTEND_ENCRYPTION_ENABLED="true" `
    WEB_CONCURRENCY="$WebConcurrency" `
    LOG_LEVEL="$LogLevel" `
    HEROKU_APP_NAME="$AppName" `
    HEROKU_BRANCH="$Branch" `
    -a $AppName

Write-Host "✅ Config vars ayarlandı!" -ForegroundColor Green
Write-Host ""
Write-Host "Kontrol için:" -ForegroundColor Yellow
Write-Host "  heroku config -a $AppName" -ForegroundColor White
