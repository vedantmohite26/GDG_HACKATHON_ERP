
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime
import os

# Configuration
SERVICE_ACCOUNT_KEY = '../../serviceAccountKey.json'

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def seed_scholarships():
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    
    # --- Delete Existing Scholarships first ---
    print("🗑️ Deleting existing scholarships...")
    docs = db.collection('scholarships').stream()
    deleted_count = 0
    batch = db.batch()
    
    for doc in docs:
        batch.delete(doc.reference)
        deleted_count += 1
        if deleted_count % 400 == 0: # Commit every 400 deletions to be safe within limit (500)
             batch.commit()
             batch = db.batch()
             
    batch.commit() # Commit remainder
    print(f"  ✅ Deleted {deleted_count} existing scholarships.")

    print("\n🌱 Seeding Scholarships...")
    
    scholarships = [
        # --- Original 5 (Updated Schema) ---
        {
            'name': 'Merit Excellence Scholarship',
            'provider': 'Techno India NJR',
            'amount': 50000,
            'description': 'Awarded to students with a CGPA above 9.0 in the previous semester.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=45),
            'category': 'Merit',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 9.0,
                'minAttendance': 0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'Need-Based Financial Aid',
            'provider': 'Government of India',
            'amount': 25000,
            'description': 'Support for students from economically weaker sections. Valid income certificate required.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=30),
            'category': 'Government',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 500000,
                'minCGPA': 0,
                'minAttendance': 0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'Women in Tech Grant',
            'provider': 'Google & Women Techmakers',
            'amount': 100000,
            'description': 'Encouraging female students pursuing degrees in Computer Science and Engineering.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=60),
            'category': 'Private',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 0,
                'minAttendance': 0,
                'categories': [],
                # Updated to use Full Branch Names
                'courses': ['Computer Engineering', 'Information Technology', 'AI & DS'], 
                'years': []
            }
        },
        {
            'name': 'Sports Achievement Award',
            'provider': 'State Sports Council',
            'amount': 15000,
            'description': 'For students who have represented the college at state or national level sports.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=15),
            'category': 'Sports',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 0,
                'minAttendance': 50.0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'Alumni Association Grant',
            'provider': 'TINJR Alumni',
            'amount': 20000,
            'description': 'Funded by our alumni network to support students showing exceptional leadership.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=90),
            'category': 'Private',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 7.0,
                'minAttendance': 0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        
        # --- New 10 ---
        {
            'name': 'Global Tech Innovators Grant',
            'provider': 'Tech Giants Consortium',
            'amount': 120000,
            'description': 'A prestigious grant for exceptional students in computer science and technology fields.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=45),
            'category': 'Private',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 8.5,
                'minAttendance': 0,
                'categories': [],
                # Updated to use Full Branch Names
                'courses': ['Computer Engineering', 'Information Technology', 'AI & DS', 'Electronics & Telecom'],
                'years': [3, 4]
            }
        },
        {
            'name': 'Future Leaders Scholarship',
            'provider': 'National Leadership Foundation',
            'amount': 40000,
            'description': 'Recognizing students with consistent academic performance and high attendance.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=30),
            'category': 'Merit',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 7.5,
                'minAttendance': 85.0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'Community Support Fund',
            'provider': 'State Government',
            'amount': 25000,
            'description': 'Financial assistance for students from economically weaker sections.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=60),
            'category': 'Government',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 300000,
                'minCGPA': 0,
                'minAttendance': 60.0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'Women in STEM Fellowship',
            'provider': 'Women Techmakers',
            'amount': 75000,
            'description': 'Empowering female students pursuing degrees in Science and Engineering.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=90),
            'category': 'Private',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 7.0,
                'minAttendance': 0,
                'categories': [],
                # Updated to use Full Branch Names
                'courses': ['Computer Engineering', 'Information Technology', 'Electronics & Telecom', 'Mechanical Engineering', 'Civil Engineering', 'Electrical Engineering'],
                'years': []
            }
        },
        {
            'name': 'State Sports Excellence Award',
            'provider': 'State Sports Council',
            'amount': 30000,
            'description': 'For students who have demonstrated excellence in sports activities.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=20),
            'category': 'Sports',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 5.0, 
                'minAttendance': 50.0,
                'categories': [],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'First Year Merit Scholarship',
            'provider': 'College Trust',
            'amount': 15000,
            'description': 'Welcoming bright minds. Exclusive for 1st-year students with outstanding entry scores.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=15),
            'category': 'Merit',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 8.0,
                'minAttendance': 0,
                'categories': [],
                'courses': [],
                'years': [1]
            }
        },
        {
            'name': 'Final Year Project Grant',
            'provider': 'Innovation Hub',
            'amount': 50000,
            'description': 'Funding for final year students to support their capstone projects and research.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=40),
            'category': 'Research',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 6.5,
                'minAttendance': 75.0,
                'categories': [],
                'courses': [],
                'years': [4]
            }
        },
        {
            'name': 'Minority Empowerment Scheme',
            'provider': 'Ministry of Minority Affairs',
            'amount': 35000,
            'description': 'Supporting students from minority communities (SC/ST/OBC).',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=25),
            'category': 'Government',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 800000,
                'minCGPA': 6.0,
                'minAttendance': 70.0,
                'categories': ['SC', 'ST', 'OBC'],
                'courses': [],
                'years': []
            }
        },
        {
            'name': 'Dr. APJ Abdul Kalam Research Fellowship',
            'provider': 'National Science Foundation',
            'amount': 100000,
            'description': 'For students showing exceptional promise in scientific research and innovation.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=120),
            'category': 'Research',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 9.0,
                'minAttendance': 90.0,
                'categories': [],
                'courses': [],
                'years': [3, 4]
            }
        },
        {
            'name': 'Arts & Culture Grant',
            'provider': 'Heritage Foundation',
            'amount': 10000,
            'description': 'For students actively involved in cultural activities and arts.',
            'deadline': datetime.datetime.now() + datetime.timedelta(days=10),
            'category': 'Private',
            'isActive': True,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'eligibilityCriteria': {
                'minIncome': 0,
                'maxIncome': 99999999,
                'minCGPA': 6.0,
                'minAttendance': 60.0,
                'categories': [],
                # Updated to use valid branches or left empty if generic
                'courses': [], 
                'years': []
            }
        },
    ]

    count = 0
    for sch in scholarships:
        db.collection('scholarships').add(sch)
        print(f"  ✅ Created scholarship: {sch['name']}")
        count += 1

    print(f"\n🎉 Successfully created {count} scholarships.")

if __name__ == "__main__":
    seed_scholarships()
