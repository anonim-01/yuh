#!/usr/bin/env python
"""Check SMS table structure"""
from app.database import get_cursor

print("Checking SMS table structure...")
with get_cursor() as cursor:
    # Get columns
    cursor.execute(
        "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = %s",
        ("sms",)
    )
    columns = cursor.fetchall()
    print("\nSMS table columns:")
    for col in columns:
        print(f"  - {col['column_name']} ({col['data_type']})")
    
    # Check if there are any records
    cursor.execute("SELECT COUNT(*) FROM sms")
    count = cursor.fetchone()['count']
    print(f"\nTotal records in SMS table: {count}")
    
    if count > 0:
        cursor.execute("SELECT * FROM sms LIMIT 3")
        print("\nSample records:")
        for row in cursor.fetchall():
            print(f"  {row}")
