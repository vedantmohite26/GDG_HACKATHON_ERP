
import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth
from firebase_admin import firestore
import json
import os

# Configuration
SERVICE_ACCOUNT_KEY = '../../serviceAccountKey.json'
DATA_FILE = 'students.json'

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def upload_data():
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    if not os.path.exists(DATA_FILE):
        print(f"❌ Error: Data file not found: {DATA_FILE}")
        return

    db = initialize_firebase()
    
    with open(DATA_FILE, 'r') as f:
        students = json.load(f)

    print(f"🚀 Starting upload of {len(students)} students...")
    
    success_count = 0
    
    for i, student in enumerate(students):
        try:
            email = student['email']
            password = student['password']
            uid = student['userId']
            student_uid = student['studentUID']
            name = student['profile']['name']
            
            print(f"Processing {i+1}/{len(students)}: {name} ({student_uid})...")

            # 1. Create Auth User
            try:
                auth.create_user(
                    uid=uid,
                    email=email,
                    password=password,
                    display_name=name,
                    email_verified=True
                )
                print(f"  ✅ Created Auth user: {email}")
            except auth.UserRecordAlreadyExistsError:
                print(f"  ⚠️ Auth user already exists: {email}")
                # We assume if auth exists, we might still update firestore, 
                # or maybe just skip auth creation.

            # 2. Upload Users Document
            user_doc = {
                'email': email,
                'role': student['role'],
                'studentUID': student_uid,
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            db.collection('users').document(uid).set(user_doc, merge=True)
            print("  ✅ Updated 'users' collection")

            # 3. Upload Student Profile
            profile_data = student['profile']
            # Convert timestamp strings to valid Firestore inputs or server timestamp
            # For simplicity in this script, we'll use server timestamp for created/updated
            # but keep the string fields as strings.
            # Ideally we parse them but the app might expect specific format or timestamp objects.
            # The seed script generated ISO strings. Firestore python client handles datetime objects or server timestamp.
            # We'll just pass the dict, but replace createdAt/updatedAt with server timestamp to be safe/fresh.
            profile_data['createdAt'] = firestore.SERVER_TIMESTAMP
            profile_data['updatedAt'] = firestore.SERVER_TIMESTAMP
            
            db.collection('student_profiles').document(student_uid).set(profile_data, merge=True)
            print("  ✅ Updated 'student_profiles' collection")

            # 4. Upload Academic Info
            academic_data = student['academicInfo']
            academic_data['createdAt'] = firestore.SERVER_TIMESTAMP
            academic_data['updatedAt'] = firestore.SERVER_TIMESTAMP
            
            db.collection('academic_info').document(student_uid).set(academic_data, merge=True)
            print("  ✅ Updated 'academic_info' collection")
            
            success_count += 1

        except Exception as e:
            print(f"❌ Error processing student {student.get('email', 'unknown')}: {e}")

    print(f"\n🎉 Finished! Successfully processed {success_count}/{len(students)} records.")

if __name__ == "__main__":
    upload_data()
