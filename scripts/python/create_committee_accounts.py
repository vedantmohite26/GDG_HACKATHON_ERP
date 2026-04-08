import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth
from firebase_admin import firestore
import os

# Configuration
SERVICE_ACCOUNT_KEY = '../../serviceAccountKey.json'

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def create_committee_accounts():
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    
    # Define 3 committee accounts (PLACEHOLDERS: Replace with actual data)
    committee_accounts = [
        {
            'email': 'committee1@example.com',
            'password': 'ChangeMe2024!',
            'name': 'Committee Member 1',
            'phone': '+91-0000000000',
            'department': 'Student Welfare',
            'designation': 'Committee Member'
        },
        {
            'email': 'committee2@example.com',
            'password': 'ChangeMe2024!',
            'name': 'Committee Member 2',
            'phone': '+91-0000000000',
            'department': 'Academic Affairs',
            'designation': 'Committee Member'
        },
        {
            'email': 'committee3@example.com',
            'password': 'ChangeMe2024!',
            'name': 'Committee Member 3',
            'phone': '+91-0000000000',
            'department': 'Finance & Accounts',
            'designation': 'Committee Member'
        }
    ]

    print(f"🚀 Creating {len(committee_accounts)} committee accounts...")
    
    success_count = 0
    
    for i, account in enumerate(committee_accounts):
        try:
            email = account['email']
            password = account['password']
            name = account['name']
            
            print(f"\nProcessing {i+1}/{len(committee_accounts)}: {name} ({email})...")

            # 1. Create Auth User
            try:
                user_record = auth.create_user(
                    email=email,
                    password=password,
                    display_name=name,
                    email_verified=True
                )
                uid = user_record.uid
                print(f"  ✅ Created Auth user: {email} (UID: {uid})")
            except auth.EmailAlreadyExistsError:
                print(f"  ⚠️  Auth user already exists: {email}")
                # Get existing user
                user_record = auth.get_user_by_email(email)
                uid = user_record.uid
                print(f"  ℹ️  Using existing UID: {uid}")

            # 2. Create/Update Users Document
            user_doc = {
                'email': email,
                'role': 'committee',
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            db.collection('users').document(uid).set(user_doc, merge=True)
            print("  ✅ Updated 'users' collection with role='committee'")

            # 3. Create Faculty Profile (Committee members are also in faculty_profiles)
            faculty_profile = {
                'employeeId': f'COM{str(i+1).zfill(3)}',
                'name': account['name'],
                'email': email,
                'department': account['department'],
                'designation': account['designation'],
                'phone': account['phone'],
                'qualification': '',
                'specialization': 'Committee Member',
                'joiningDate': firestore.SERVER_TIMESTAMP,
                'profilePhoto': '',
                'isVerified': True,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP
            }
            db.collection('faculty_profiles').document(uid).set(faculty_profile, merge=True)
            print("  ✅ Created 'faculty_profiles' entry")
            
            success_count += 1
            print(f"  ✨ Success! Account ready: {email} / {password}")

        except Exception as e:
            print(f"❌ Error processing {account.get('email', 'unknown')}: {e}")

    print(f"\n🎉 Finished! Successfully created {success_count}/{len(committee_accounts)} committee accounts.")
    print("\n📋 Login Credentials:")
    for account in committee_accounts:
        print(f"   • {account['email']} / {account['password']}")

if __name__ == "__main__":
    create_committee_accounts()
