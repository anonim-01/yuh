from __future__ import annotations

from flask import Flask, Response, request

from .config import AppConfig, STATIC_DIR
from .ip_blocker import check_ip_blocked
from .routes.admin import admin_bp
from .routes.binlookup import binlookup_bp
from .routes.commands import commands_bp
from .routes.public import public_bp
from .services.settings import get_settings as get_app_settings


def create_app() -> Flask:
    app = Flask(__name__, static_folder=str(STATIC_DIR), static_url_path="/assets", template_folder="../templates")
    app.config["SECRET_KEY"] = AppConfig.secret_key

    # IP engelleme middleware'ini ekle
    app.before_request(check_ip_blocked)
    
    # Güvenlik header'larını ekle
    @app.after_request
    def add_security_headers(response: Response) -> Response:
        # Content-Type charset UTF-8
        if 'Content-Type' in response.headers and 'charset' not in response.headers['Content-Type']:
            if 'text/' in response.headers['Content-Type'] or 'application/json' in response.headers['Content-Type']:
                response.headers['Content-Type'] += '; charset=utf-8'
        
        # X-Content-Type-Options
        response.headers['X-Content-Type-Options'] = 'nosniff'
        
        # Cache-Control (static dosyalar için)
        if request.path.startswith('/assets/'):
            # Static dosyalar için 1 yıl cache
            response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
        elif request.path.startswith('/admin/'):
            # Admin sayfaları için no-cache
            response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, private'
        else:
            # Diğer sayfalar için kısa cache
            response.headers['Cache-Control'] = 'public, max-age=300'
        
        # Content Security Policy (eval kullanımı için unsafe-eval ekledik)
        csp_directives = [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://code.jquery.com https://cdnjs.cloudflare.com",
            "style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com",
            "font-src 'self' https://cdnjs.cloudflare.com https://fonts.gstatic.com data:",
            "img-src 'self' data: https:",
            "connect-src 'self'",
            "frame-ancestors 'none'",
        ]
        response.headers['Content-Security-Policy'] = '; '.join(csp_directives)
        
        # X-XSS-Protection ve X-Frame-Options kaldırıldı (deprecated)
        # Bunların yerine CSP kullanılıyor
        response.headers.pop('X-XSS-Protection', None)
        response.headers.pop('X-Frame-Options', None)
        response.headers.pop('Expires', None)  # Cache-Control kullanıyoruz
        
        return response

    app.register_blueprint(public_bp)
    app.register_blueprint(commands_bp)
    app.register_blueprint(binlookup_bp)
    app.register_blueprint(admin_bp)

    @app.context_processor
    def inject_app_settings():  # pragma: no cover - template helper
        return {"app_settings": get_app_settings()}

    return app
