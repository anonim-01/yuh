# Heroku Config Vars Ayarlama Scripti
# Kullanım: .\set_heroku_config.ps1 -AppName "your-app-name"

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Heroku Config Vars Ayarlama" -ForegroundColor Cyan
Write-Host "Uygulama: $AppName" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Heroku CLI kontrolü
try {
    $null = Get-Command heroku -ErrorAction Stop
    Write-Host "✓ Heroku CLI yüklü" -ForegroundColor Green
} catch {
    Write-Host "❌ Heroku CLI bulunamadı! Lütfen önce yükleyin:" -ForegroundColor Red
    Write-Host "   https://cli-assets.heroku.com/heroku-x64.exe" -ForegroundColor Yellow
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

Write-Host ""
Write-Host "Config değişkenleri ayarlanıyor..." -ForegroundColor Cyan
Write-Host ""

# 1. FLASK_SECRET_KEY (ZORUNLU)
Write-Host "1. FLASK_SECRET_KEY ayarlanıyor..." -ForegroundColor Yellow
$secretKey = heroku config:get FLASK_SECRET_KEY -a $AppName 2>$null
if ([string]::IsNullOrWhiteSpace($secretKey)) {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $secretKey = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLower()
    heroku config:set FLASK_SECRET_KEY="$secretKey" -a $AppName
    Write-Host "   ✓ FLASK_SECRET_KEY oluşturuldu ve ayarlandı" -ForegroundColor Green
} else {
    Write-Host "   ✓ FLASK_SECRET_KEY zaten mevcut" -ForegroundColor Green
}

# 2. FRONTEND_ENCRYPTION_ENABLED
Write-Host "2. FRONTEND_ENCRYPTION_ENABLED ayarlanıyor..." -ForegroundColor Yellow
heroku config:set FRONTEND_ENCRYPTION_ENABLED="true" -a $AppName | Out-Null
Write-Host "   ✓ FRONTEND_ENCRYPTION_ENABLED = true" -ForegroundColor Green

# 3. WEB_CONCURRENCY
Write-Host "3. WEB_CONCURRENCY ayarlanıyor..." -ForegroundColor Yellow
$response = Read-Host "   Worker sayısı? (varsayılan: 2, önerilen: 2-4)"
if ([string]::IsNullOrWhiteSpace($response)) {
    $workerCount = "2"
} else {
    $workerCount = $response
}
heroku config:set WEB_CONCURRENCY="$workerCount" -a $AppName | Out-Null
Write-Host "   ✓ WEB_CONCURRENCY = $workerCount" -ForegroundColor Green

# 4. LOG_LEVEL
Write-Host "4. LOG_LEVEL ayarlanıyor..." -ForegroundColor Yellow
$response = Read-Host "   Log seviyesi? (debug/info/warning/error, varsayılan: info)"
if ([string]::IsNullOrWhiteSpace($response)) {
    $logLevel = "info"
} else {
    $logLevel = $response.ToLower()
}
heroku config:set LOG_LEVEL="$logLevel" -a $AppName | Out-Null
Write-Host "   ✓ LOG_LEVEL = $logLevel" -ForegroundColor Green

# 5. HEROKU_APP_NAME (otomatik)
Write-Host "5. HEROKU_APP_NAME ayarlanıyor..." -ForegroundColor Yellow
heroku config:set HEROKU_APP_NAME="$AppName" -a $AppName | Out-Null
Write-Host "   ✓ HEROKU_APP_NAME = $AppName" -ForegroundColor Green

# 6. HEROKU_BRANCH (varsayılan: main)
Write-Host "6. HEROKU_BRANCH ayarlanıyor..." -ForegroundColor Yellow
$currentBranch = git branch --show-current
$response = Read-Host "   Deploy branch? (varsayılan: $currentBranch)"
if ([string]::IsNullOrWhiteSpace($response)) {
    $branch = $currentBranch
} else {
    $branch = $response
}
heroku config:set HEROKU_BRANCH="$branch" -a $AppName | Out-Null
Write-Host "   ✓ HEROKU_BRANCH = $branch" -ForegroundColor Green

# 7. HEROKU_PR_NUMBER (opsiyonel, review apps için)
Write-Host "7. HEROKU_PR_NUMBER (opsiyonel, Enter ile geç)..." -ForegroundColor Yellow
$prNumber = Read-Host "   PR numarası? (boş bırakılabilir)"
if (![string]::IsNullOrWhiteSpace($prNumber)) {
    heroku config:set HEROKU_PR_NUMBER="$prNumber" -a $AppName | Out-Null
    Write-Host "   ✓ HEROKU_PR_NUMBER = $prNumber" -ForegroundColor Green
} else {
    Write-Host "   ⊘ HEROKU_PR_NUMBER atlandı" -ForegroundColor Gray
}

# Opsiyonel: Cloudflare ayarları
Write-Host ""
$response = Read-Host "Cloudflare ayarlarını yapmak ister misiniz? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host ""
    Write-Host "Cloudflare Config Vars:" -ForegroundColor Cyan
    
    $cfAccountId = Read-Host "CLOUDFLARE_ACCOUNT_ID"
    if (![string]::IsNullOrWhiteSpace($cfAccountId)) {
        heroku config:set CLOUDFLARE_ACCOUNT_ID="$cfAccountId" -a $AppName | Out-Null
        Write-Host "✓ CLOUDFLARE_ACCOUNT_ID ayarlandı" -ForegroundColor Green
    }
    
    $cfApiToken = Read-Host "CLOUDFLARE_API_TOKEN"
    if (![string]::IsNullOrWhiteSpace($cfApiToken)) {
        heroku config:set CLOUDFLARE_API_TOKEN="$cfApiToken" -a $AppName | Out-Null
        Write-Host "✓ CLOUDFLARE_API_TOKEN ayarlandı" -ForegroundColor Green
    }
    
    $cfAuthEmail = Read-Host "CLOUDFLARE_AUTH_EMAIL"
    if (![string]::IsNullOrWhiteSpace($cfAuthEmail)) {
        heroku config:set CLOUDFLARE_AUTH_EMAIL="$cfAuthEmail" -a $AppName | Out-Null
        Write-Host "✓ CLOUDFLARE_AUTH_EMAIL ayarlandı" -ForegroundColor Green
    }
    
    $cfAuthKey = Read-Host "CLOUDFLARE_AUTH_KEY"
    if (![string]::IsNullOrWhiteSpace($cfAuthKey)) {
        heroku config:set CLOUDFLARE_AUTH_KEY="$cfAuthKey" -a $AppName | Out-Null
        Write-Host "✓ CLOUDFLARE_AUTH_KEY ayarlandı" -ForegroundColor Green
    }
    
    $cfZoneId = Read-Host "CLOUDFLARE_ZONE_ID"
    if (![string]::IsNullOrWhiteSpace($cfZoneId)) {
        heroku config:set CLOUDFLARE_ZONE_ID="$cfZoneId" -a $AppName | Out-Null
        Write-Host "✓ CLOUDFLARE_ZONE_ID ayarlandı" -ForegroundColor Green
    }
    
    $cfSslHosts = Read-Host "CLOUDFLARE_SSL_HOSTS (virgülle ayırın)"
    if (![string]::IsNullOrWhiteSpace($cfSslHosts)) {
        heroku config:set CLOUDFLARE_SSL_HOSTS="$cfSslHosts" -a $AppName | Out-Null
        Write-Host "✓ CLOUDFLARE_SSL_HOSTS ayarlandı" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ Tüm config vars ayarlandı!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Tüm config vars'ları göster
Write-Host "Mevcut Config Vars:" -ForegroundColor Cyan
Write-Host ""
heroku config -a $AppName

Write-Host ""
Write-Host "Deployment yapmak için:" -ForegroundColor Yellow
Write-Host "  git push heroku $($branch):main" -ForegroundColor White
Write-Host ""
Write-Host "Uygulamayı açmak için:" -ForegroundColor Yellow
Write-Host "  heroku open -a $AppName" -ForegroundColor White
