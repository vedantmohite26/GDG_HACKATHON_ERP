
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import random
from datetime import datetime, timedelta

# Configuration
SERVICE_ACCOUNT_KEY = '../../serviceAccountKey.json'

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def seed_data():
    db = initialize_firebase()
    print("🌱 Connecting to Firestore...")

    # 1. Fetch Students
    print("Fetching students...")
    students_snapshot = db.collection('users').where('role', '==', 'student').stream()
    students = []
    for doc in students_snapshot:
        data = doc.to_dict()
        if 'studentUID' in data:
            students.append({'uid': doc.id, 'studentUID': data['studentUID']})
    
    print(f"✅ Found {len(students)} students.")

    # 2. Fetch Committee Members
    print("Fetching committee members...")
    committee_snapshot = db.collection('users').where('role', '==', 'committee').stream()
    committee_members = [doc.id for doc in committee_snapshot]
    print(f"✅ Found {len(committee_members)} committee members.")

    # 3. Fetch Scholarships
    print("Fetching scholarships...")
    scholarships_snapshot = db.collection('scholarships').stream()
    scholarships = [doc.id for doc in scholarships_snapshot]
    print(f"✅ Found {len(scholarships)} scholarships.")

    if not students:
        print("❌ No students found. Run student seeding first.")
        return

    # Seed Applications
    print("\n📦 Seeding Applications...")
    app_count = 0
    for student in students:
        # 50% chance to apply
        if random.random() > 0.5 and scholarships:
            scholarship_id = random.choice(scholarships)
            status_opts = ['pending', 'approved', 'rejected']
            status = random.choice(status_opts)
            submitted_at = datetime.now() - timedelta(days=random.randint(1, 30))
            
            app_data = {
                'studentUID': student['studentUID'],
                'scholarshipId': scholarship_id,
                'status': status,
                'submittedAt': submitted_at,
            }

            if status != 'pending':
                app_data['reviewedAt'] = submitted_at + timedelta(days=random.randint(1, 5))
                app_data['reviewedBy'] = 'admin_script' # Placeholder admin ID
                app_data['adminNotes'] = 'Auto-generated review decision.'

            db.collection('applications').add(app_data)
            app_count += 1
    print(f"✅ Created {app_count} applications.")

    # Seed Grievances
    print("\n📦 Seeding Grievances...")
    grievance_count = 0
    categories = ['Academic', 'Hostel', 'Cafeteria', 'Library', 'Other']
    
    for student in students:
        # 50% chance to have a grievance
        if random.random() > 0.5:
            category = random.choice(categories)
            status_opts = ['pending', 'assigned', 'in-progress', 'resolved']
            status = random.choice(status_opts)
            submitted_at = datetime.now() - timedelta(days=random.randint(1, 15))
            sla_deadline = submitted_at + timedelta(days=7) # 7 day SLA

            grievance_data = {
                'studentUID': student['studentUID'],
                'category': category,
                'description': f"This is a test grievance regarding {category.lower()} issues. Please resolve.",
                'isAnonymous': random.random() < 0.2, # 20% confidential
                'proofUrls': [],
                'priorityScore': random.randint(1, 10),
                'status': status,
                'submittedAt': submitted_at,
                'slaDeadline': sla_deadline,
            }

            if status != 'pending' and committee_members:
                assigned_to = random.choice(committee_members)
                grievance_data['assignedTo'] = assigned_to
            
            if status == 'resolved':
                grievance_data['resolvedAt'] = submitted_at + timedelta(days=random.randint(1, 5))
                grievance_data['resolvedBy'] = grievance_data.get('assignedTo', 'committee_script')
                grievance_data['internalNotes'] = 'Resolved via seeding script.'

            db.collection('grievances').add(grievance_data)
            grievance_count += 1
            
    print(f"✅ Created {grievance_count} grievances.")
    print("\n🎉 Seeding Complete!")

if __name__ == "__main__":
    seed_data()
