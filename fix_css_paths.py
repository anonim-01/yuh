#!/usr/bin/env python3
"""Fix CSS image paths from /themes/izmir/ to /static/img/"""

import re
from pathlib import Path

# CSS dosyaları
css_files = [
    'static/css/base.css',
    'static/css/giris.css',
    'static/css/admin-custom.css'
]

# Yol değişiklikleri
replacements = {
    r'/themes/izmir/+images/': '/static/img/',
    r'/themes/izmir//+images/': '/static/img/'
}

for css_file in css_files:
    file_path = Path(css_file)
    if not file_path.exists():
        print(f"⚠️  Bulunamadı: {css_file}")
        continue
    
    content = file_path.read_text(encoding='utf-8')
    original_content = content
    
    # Tüm değişiklikleri uygula
    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content)
    
    if content != original_content:
        file_path.write_text(content, encoding='utf-8')
        print(f"✅ Düzeltildi: {css_file}")
    else:
        print(f"ℹ️  Değişiklik yok: {css_file}")

print("\n✨ Tamamlandı!")
