
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime
import os
import random

# Configuration
SERVICE_ACCOUNT_KEY = '../../serviceAccountKey.json'

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def seed_events():
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    print("🌱 Seeding Events/Notices...")

    events = [
        {
            'title': 'Hack-a-Thon 2024 Registration Open',
            'description': 'Register now for the biggest coding event of the year! Teams of 4 allowed. Win prizes worth 1 Lakh.',
            'date': datetime.datetime.now() + datetime.timedelta(days=10),
            'location': 'Main Auditorium',
            'organizer': 'InfinIT Club',
            'type': 'Competition',
            'createdAt': firestore.SERVER_TIMESTAMP,
        },
        {
            'title': 'Mid-Semester Exam Schedule',
            'description': 'The schedule for upcoming mid-semester exams has been released. Check the academic portal for details.',
            'date': datetime.datetime.now() + datetime.timedelta(days=5),
            'location': 'Examination Hall',
            'organizer': 'Exam Cell',
            'type': 'Academic',
            'createdAt': firestore.SERVER_TIMESTAMP,
        },
        {
            'title': 'Guest Lecture: AI in Healthcare',
            'description': 'Dr. Sharma from AIIMS will discuss the future of AI in medical diagnostics.',
            'date': datetime.datetime.now() + datetime.timedelta(days=2),
            'location': 'Seminar Hall 1',
            'organizer': 'Research Dept',
            'type': 'Seminar',
            'createdAt': firestore.SERVER_TIMESTAMP,
        },
        {
            'title': 'Cultural Fest "Udbhav" Auditions',
            'description': 'Auditions for Dance, Music, and Drama events starting this Monday.',
            'date': datetime.datetime.now() + datetime.timedelta(days=7),
            'location': 'Open Air Theatre',
            'organizer': 'Cultural Committee',
            'type': 'Cultural',
            'createdAt': firestore.SERVER_TIMESTAMP,
        },
        {
            'title': 'Campus Placement Drive: TCS',
            'description': 'TCS recruitment drive for final year students. Pre-placement talk at 10 AM.',
            'date': datetime.datetime.now() + datetime.timedelta(days=12),
            'location': 'Placement Cell',
            'organizer': 'TnP Cell',
            'type': 'Placement',
            'createdAt': firestore.SERVER_TIMESTAMP,
        },
    ]

    count = 0
    for evt in events:
        db.collection('events').add(evt)
        print(f"  ✅ Created event: {evt['title']}")
        count += 1

    print(f"\n🎉 Successfully created {count} events.")

if __name__ == "__main__":
    seed_events()
