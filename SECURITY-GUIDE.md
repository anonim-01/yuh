# 🔐 Güvenlik ve Anonimlik Sistemi

## Genel Bakış

Bu sistem, sunucu IP'sini ve host bilgilerini gizlemek için kapsamlı güvenlik önlemleri içerir.

## Özellikler

### 1. IP Anonimleştirme (`IPAnonymizer`)

**Sahte IP Üretimi:**
```python
from app.security import IPAnonymizer

# Gerçekçi sahte IP üret
fake_ip = IPAnonymizer.generate_fake_ip()
# Örnek: 192.168.42.157
```

**Gerçek IP'yi Hash'le:**
```python
# Gerçek IP'yi sakla ama açığa çıkarma
hashed = IPAnonymizer.hash_real_ip("185.67.32.10")
# Sonuç: "a3f8d9c2e1b4a7f6:1a2b3c4d5e6f7g8h"
```

**Oturum Bazlı IP Rotasyonu:**
```python
# Her 5 dakikada bir otomatik IP değişimi
rotating_ip = IPAnonymizer.get_rotating_proxy_ip(session_id="user123")
```

### 2. Host Gizleme (`HostAnonymizer`)

**Sahte Host Header:**
```python
from app.security import HostAnonymizer

# CDN/Cloud provider host'u kullan
fake_host = HostAnonymizer.get_fake_host()
# Örnek: "cdn.cloudflare.net", "edge.akamai.com"
```

**Header Temizleme:**
```python
# Tehlikeli header'ları kaldır, sahte ekle
safe_headers = HostAnonymizer.sanitize_headers(request)
# X-Forwarded-For, X-Real-IP, Host → sahte değerler
```

### 3. Sunucu Kimliği Gizleme (`ServerIdentityHider`)

**Sahte Lokasyon:**
```python
from app.security import ServerIdentityHider

location = ServerIdentityHider.get_fake_server_location()
# {"country": "Singapore", "city": "Singapore", "isp": "DigitalOcean"}
```

**Anonim Loglama:**
```python
# Gerçek sunucu bilgisi olmadan log kaydet
ServerIdentityHider.log_access_with_anonymization(
    ip="185.67.32.10",
    user_agent="Mozilla/5.0..."
)
# anonymous_logs tablosuna hash'lenmiş IP + sahte lokasyon kaydedilir
```

### 4. Proxy Rotasyonu (`ProxyRotation`)

**Proxy Ekle:**
```python
from app.security import ProxyRotation

# Proxy pool'a ekle
ProxyRotation.add_proxy("http://proxy1.example.com:8080")
ProxyRotation.add_proxy("socks5://proxy2.example.com:1080")
```

**Aktif Proxy Al:**
```python
# 30 saniye aralarla otomatik rotasyon
proxy = ProxyRotation.get_current_proxy()
if proxy:
    response = requests.get(url, proxies={"http": proxy, "https": proxy})
```

**Ölü Proxy İşaretle:**
```python
# Çalışmayan proxy'i devre dışı bırak
ProxyRotation.mark_proxy_dead("http://dead-proxy.com:8080")
```

## Veritabanı Tabloları

### `ip_rotation`
```sql
CREATE TABLE ip_rotation (
    session_id TEXT PRIMARY KEY,
    fake_ip TEXT NOT NULL,
    created_at TEXT NOT NULL
);
```
- Her oturuma özel sahte IP
- 5 dakikada bir otomatik yenilenir

### `anonymous_logs`
```sql
CREATE TABLE anonymous_logs (
    id INTEGER PRIMARY KEY,
    hashed_ip TEXT NOT NULL,
    user_agent TEXT,
    fake_country TEXT,
    fake_city TEXT,
    fake_isp TEXT,
    timestamp TEXT NOT NULL
);
```
- Gerçek IP hash'lenir
- Sahte coğrafi konum bilgisi
- Gerçek sunucu konumu gizlenir

### `proxy_pool`
```sql
CREATE TABLE proxy_pool (
    proxy_url TEXT PRIMARY KEY,
    active INTEGER DEFAULT 1,
    last_used TEXT NOT NULL,
    success_count INTEGER DEFAULT 0,
    fail_count INTEGER DEFAULT 0
);
```
- Proxy rotasyon havuzu
- Başarı/hata istatistikleri
- Otomatik ölü proxy tespiti

## Kullanım Örnekleri

### Admin Panel Entegrasyonu

```python
from app.security import IPAnonymizer, ServerIdentityHider
from flask import session

@admin_bp.route("/logs")
def logs():
    # Gerçek IP'yi hash'le
    real_ip = get_client_ip(request)
    hashed_ip = IPAnonymizer.hash_real_ip(real_ip)
    
    # Sahte rotasyon IP'si al
    fake_ip = IPAnonymizer.get_rotating_proxy_ip(session.sid)
    
    # Anonim log kaydet
    ServerIdentityHider.log_access_with_anonymization(
        ip=real_ip,
        user_agent=request.headers.get("User-Agent")
    )
    
    return render_template("admin/logs.html", 
                         display_ip=fake_ip,
                         server_location="Hidden")
```

### Dış İstek Güvenliği

```python
import requests
from app.security import ProxyRotation, HostAnonymizer

def make_secure_request(url):
    # Proxy al
    proxy = ProxyRotation.get_current_proxy()
    
    # Sahte header'lar
    headers = {
        "Host": HostAnonymizer.get_fake_host(),
        "X-Forwarded-For": IPAnonymizer.generate_fake_ip(),
    }
    
    try:
        response = requests.get(
            url,
            proxies={"http": proxy, "https": proxy},
            headers=headers,
            timeout=10
        )
        return response
    except requests.RequestException:
        # Proxy çalışmıyor, işaretle
        if proxy:
            ProxyRotation.mark_proxy_dead(proxy)
        return None
```

## Güvenlik Katmanları

1. **IP Katmanı**: Gerçek IP hash'lenir, sahte IP rotasyonu
2. **Host Katmanı**: Gerçek host gizlenir, CDN/cloud host'ları kullanılır
3. **Proxy Katmanı**: Çoklu proxy rotasyonu, ölü proxy otomatik tespit
4. **Log Katmanı**: Anonim loglama, sahte coğrafi bilgi
5. **Header Katmanı**: Tehlikeli header temizleme, sahte header ekleme

## Cloudflare Entegrasyonu

Sistem şu anda Cloudflare kullanıyor, bu ek bir koruma katmanı:

- **CF-Connecting-IP**: Cloudflare gerçek IP'yi header'da gönderir
- **SSL/TLS**: Otomatik SSL sertifikaları
- **DDoS Koruması**: Cloudflare layer 7 koruması
- **WAF**: Web Application Firewall kuralları

## Öneriler

1. **Çoklu Proxy Kullanın**: En az 5-10 proxy ekleyin
2. **Proxy Rotasyonunu Test Edin**: `ProxyRotation.get_all_active_proxies()`
3. **Log Takibi**: `anonymous_logs` tablosunu düzenli kontrol edin
4. **IP Rotasyonu**: 5 dakikalık interval'i ihtiyaca göre ayarlayın
5. **Cloudflare Aktif**: DNS ve SSL Cloudflare üzerinden gitmeli

## Güvenlik Testleri

```bash
# IP'nizi test edin
curl https://api.ipify.org

# Header'ları test edin
curl -I https://your-domain.com

# Proxy'leri test edin
curl -x http://proxy:port https://api.ipify.org
```

## Acil Durum

Eğer gerçek IP açığa çıkarsa:

1. Hemen yeni Cloudflare tunnel oluşturun
2. Tüm proxy'leri yenileyin
3. `ip_rotation` tablosunu temizleyin
4. Yeni domain alias ekleyin
5. Heroku dyno'yu yeniden başlatın

## Önemli Notlar

⚠️ **Asla Gerçek IP'yi Log'lamayın**: Sadece hash'lenmiş versiyonunu saklayın
⚠️ **Proxy Listesini Güncel Tutun**: Ölü proxy'leri temizleyin
⚠️ **Header Sızıntılarını Kontrol Edin**: `sanitize_headers` kullanın
⚠️ **Cloudflare'i Bypass Etmeyin**: Tüm trafik Cloudflare üzerinden gitm eli
