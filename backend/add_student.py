"""
Add Student/Alumni to College Registry
---------------------------------------
Usage:
  python add_student.py

This script connects to your Supabase database using the credentials
in your .env file and adds new college records so students can register.
"""

import asyncio
import sys
from dotenv import load_dotenv

load_dotenv()

from sqlalchemy import select
from app.database import SessionLocal
from app.models import CollegeRecord, UserRole


async def add_record(usn: str, full_name: str, email: str, phone: str, role: str, branch: str, grad_year: int):
    async with SessionLocal() as session:
        # Check if USN already exists
        existing = await session.execute(
            select(CollegeRecord).where(CollegeRecord.usn == usn)
        )
        if existing.scalars().first():
            print(f"[SKIP] USN '{usn}' already exists in the registry. Skipping.")
            return

        record = CollegeRecord(
            usn=usn,
            full_name=full_name,
            email=email,
            phone_number=phone,
            role=UserRole.student if role == "student" else UserRole.alumni,
            branch=branch,
            graduation_year=grad_year
        )
        session.add(record)
        await session.commit()
        print(f"[OK] Added: {full_name} ({usn}) as {role} - {branch}, Class of {grad_year}")


async def list_records():
    async with SessionLocal() as session:
        result = await session.execute(select(CollegeRecord))
        records = result.scalars().all()
        if not records:
            print("No college records found.")
            return
        print(f"\n{'USN':<15} {'Name':<25} {'Role':<10} {'Branch':<20} {'Year'}")
        print("-" * 80)
        for r in records:
            print(f"{r.usn:<15} {r.full_name:<25} {r.role.value:<10} {r.branch or '':<20} {r.graduation_year or ''}")
        print(f"\nTotal: {len(records)} records\n")


async def main():
    print("\n=== Alumnix College Registry Manager ===\n")
    print("1. Add a new student")
    print("2. Add a new alumni")
    print("3. View all registry records")
    print("4. Exit")

    choice = input("\nChoose an option (1-4): ").strip()

    if choice == "1" or choice == "2":
        role = "student" if choice == "1" else "alumni"
        print(f"\n--- Adding new {role} ---")
        usn = input("USN (e.g. 1RV22CS050): ").strip().upper()
        full_name = input("Full Name: ").strip()
        email = input("Email: ").strip()
        phone = input("Phone (with +91): ").strip()
        branch = input("Branch (e.g. Computer Science): ").strip()
        grad_year = int(input("Graduation Year (e.g. 2026): ").strip())

        await add_record(usn, full_name, email, phone, role, branch, grad_year)

    elif choice == "3":
        await list_records()

    elif choice == "4":
        print("Bye!")
        sys.exit(0)
    else:
        print("Invalid option.")


if __name__ == "__main__":
    asyncio.run(main())
