"""
Security module for IP hiding, proxy rotation, and server anonymization.
Prevents tracking of real server IP and host information.
"""
from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from flask import Request

from .database import execute, fetch_one, fetch_all


class IPAnonymizer:
    """Anonymize and rotate IP addresses for security"""
    
    @staticmethod
    def generate_fake_ip() -> str:
        """Generate realistic-looking fake IP address"""
        octets = [
            secrets.choice([10, 172, 192]),  # Private IP ranges
            secrets.randbelow(256),
            secrets.randbelow(256),
            secrets.randbelow(256)
        ]
        return f"{octets[0]}.{octets[1]}.{octets[2]}.{octets[3]}"
    
    @staticmethod
    def hash_real_ip(ip: str, salt: Optional[str] = None) -> str:
        """Hash real IP for storage without revealing actual IP"""
        if not salt:
            salt = secrets.token_hex(16)
        combined = f"{ip}:{salt}"
        hashed = hashlib.sha256(combined.encode()).hexdigest()
        return f"{hashed[:16]}:{salt}"
    
    @staticmethod
    def get_rotating_proxy_ip(session_id: str) -> str:
        """Get a rotating fake IP based on session"""
        # Check if we have a fake IP for this session
        result = fetch_one(
            "SELECT fake_ip, created_at FROM ip_rotation WHERE session_id=? LIMIT 1",
            [session_id]
        )
        
        if result and result.get("fake_ip"):
            # Check if IP is still valid (rotate every 5 minutes)
            created = result.get("created_at", "")
            if created:
                created_time = datetime.fromisoformat(created.replace("Z", "+00:00"))
                if datetime.now(timezone.utc) - created_time < timedelta(minutes=5):
                    return result["fake_ip"]
        
        # Generate new fake IP and store
        fake_ip = IPAnonymizer.generate_fake_ip()
        execute(
            """
            INSERT OR REPLACE INTO ip_rotation (session_id, fake_ip, created_at)
            VALUES (?, ?, ?)
            """,
            [session_id, fake_ip, datetime.now(timezone.utc).isoformat()]
        )
        return fake_ip


class HostAnonymizer:
    """Hide real server host and domain information"""
    
    @staticmethod
    def get_fake_host() -> str:
        """Generate believable fake host header"""
        fake_domains = [
            "cdn.cloudflare.net",
            "edge.akamai.com",
            "cache.googleapis.com",
            "s3.amazonaws.com",
            "azure.microsoft.com"
        ]
        return secrets.choice(fake_domains)
    
    @staticmethod
    def sanitize_headers(request: Request) -> dict[str, str]:
        """Remove revealing headers and replace with fake ones"""
        safe_headers = {}
        
        # Only keep safe headers
        safe_list = ["User-Agent", "Accept", "Accept-Language", "Accept-Encoding"]
        for header in safe_list:
            value = request.headers.get(header)
            if value:
                safe_headers[header] = value
        
        # Add fake headers
        safe_headers["X-Forwarded-For"] = IPAnonymizer.generate_fake_ip()
        safe_headers["X-Real-IP"] = IPAnonymizer.generate_fake_ip()
        safe_headers["Host"] = HostAnonymizer.get_fake_host()
        
        return safe_headers


class ServerIdentityHider:
    """Hide server identity and location"""
    
    @staticmethod
    def get_fake_server_location() -> dict[str, str]:
        """Return fake server geolocation data"""
        fake_locations = [
            {"country": "Singapore", "city": "Singapore", "isp": "DigitalOcean"},
            {"country": "Netherlands", "city": "Amsterdam", "isp": "Hetzner"},
            {"country": "United States", "city": "New York", "isp": "AWS"},
            {"country": "Germany", "city": "Frankfurt", "isp": "Google Cloud"},
            {"country": "United Kingdom", "city": "London", "isp": "Microsoft Azure"},
        ]
        return secrets.choice(fake_locations)
    
    @staticmethod
    def log_access_with_anonymization(ip: str, user_agent: str) -> None:
        """Log access attempts without revealing real server info"""
        hashed_ip = IPAnonymizer.hash_real_ip(ip)
        fake_location = ServerIdentityHider.get_fake_server_location()
        
        execute(
            """
            INSERT INTO anonymous_logs (
                hashed_ip, user_agent, fake_country, fake_city, fake_isp, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                hashed_ip,
                user_agent,
                fake_location["country"],
                fake_location["city"],
                fake_location["isp"],
                datetime.now(timezone.utc).isoformat()
            ]
        )


class ProxyRotation:
    """Manage proxy rotation for outgoing requests"""
    
    @staticmethod
    def get_current_proxy() -> Optional[str]:
        """Get currently active proxy"""
        result = fetch_one(
            """
            SELECT proxy_url FROM proxy_pool 
            WHERE active=1 AND last_used < datetime('now', '-30 seconds')
            ORDER BY last_used ASC
            LIMIT 1
            """
        )
        
        if result and result.get("proxy_url"):
            proxy_url = result["proxy_url"]
            # Update last used time
            execute(
                "UPDATE proxy_pool SET last_used=? WHERE proxy_url=?",
                [datetime.now(timezone.utc).isoformat(), proxy_url]
            )
            return proxy_url
        return None
    
    @staticmethod
    def add_proxy(proxy_url: str) -> None:
        """Add new proxy to rotation pool"""
        execute(
            """
            INSERT OR IGNORE INTO proxy_pool (proxy_url, active, last_used)
            VALUES (?, 1, ?)
            """,
            [proxy_url, datetime.now(timezone.utc).isoformat()]
        )
    
    @staticmethod
    def mark_proxy_dead(proxy_url: str) -> None:
        """Mark proxy as inactive"""
        execute(
            "UPDATE proxy_pool SET active=0 WHERE proxy_url=?",
            [proxy_url]
        )
    
    @staticmethod
    def get_all_active_proxies() -> list[dict[str, str]]:
        """Get list of all active proxies"""
        return fetch_all("SELECT * FROM proxy_pool WHERE active=1 ORDER BY last_used ASC")


def init_security_tables() -> None:
    """Initialize security-related database tables"""
    from .database import get_connection
    
    conn = get_connection()
    cursor = conn.cursor()
    
    # IP rotation table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS ip_rotation (
            session_id TEXT PRIMARY KEY,
            fake_ip TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
    """)
    
    # Anonymous logs table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS anonymous_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hashed_ip TEXT NOT NULL,
            user_agent TEXT,
            fake_country TEXT,
            fake_city TEXT,
            fake_isp TEXT,
            timestamp TEXT NOT NULL
        )
    """)
    
    # Proxy pool table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS proxy_pool (
            proxy_url TEXT PRIMARY KEY,
            active INTEGER DEFAULT 1,
            last_used TEXT NOT NULL,
            success_count INTEGER DEFAULT 0,
            fail_count INTEGER DEFAULT 0
        )
    """)
    
    conn.commit()
    conn.close()
