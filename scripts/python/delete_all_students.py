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

def delete_all_student_data():
    """
    ⚠️ WARNING: This will DELETE ALL student data from the database!
    This includes:
    - Firebase Auth users with role='student'
    - Firestore 'users' collection documents
    - Firestore 'student_profiles' collection documents
    - All 'applications' collection documents
    - All 'grievances' collection documents
    - All 'academic_info' collection documents
    - All 'documents_meta' collection documents
    """
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    
    print("\n" + "=" * 80)
    print("⚠️  WARNING: DESTRUCTIVE OPERATION ⚠️")
    print("=" * 80)
    print("\nThis will DELETE ALL student data including:")
    print("  • All student user accounts (Firebase Auth)")
    print("  • All student profiles")
    print("  • All scholarship applications")
    print("  • All grievances")
    print("  • All academic info")
    print("  • All document metadata")
    print("\nAdmin, Committee, and Faculty accounts will NOT be affected.")
    print("=" * 80)
    
    # Ask for confirmation
    response = input("\n❓ Are you ABSOLUTELY SURE you want to proceed? (type 'DELETE ALL STUDENTS'): ")
    
    if response != 'DELETE ALL STUDENTS':
        print("\n❌ Operation cancelled. No data was deleted.")
        return
    
    print("\n🗑️  Starting deletion process...\n")
    
    # 1. Get all student UIDs from users collection
    print("📋 Step 1: Finding all student users...")
    student_users = db.collection('users').where('role', '==', 'student').stream()
    student_uids = [doc.id for doc in student_users]
    print(f"   Found {len(student_uids)} student users")
    
    # 2. Delete from Firebase Auth
    print("\n🔐 Step 2: Deleting from Firebase Auth...")
    auth_deleted = 0
    for uid in student_uids:
        try:
            auth.delete_user(uid)
            auth_deleted += 1
            if auth_deleted % 10 == 0:
                print(f"   Deleted {auth_deleted}/{len(student_uids)} Auth users...")
        except Exception as e:
            print(f"   ⚠️  Failed to delete Auth user {uid}: {e}")
    print(f"   ✅ Deleted {auth_deleted} Firebase Auth users")
    
    # 3. Delete from users collection
    print("\n👤 Step 3: Deleting from 'users' collection...")
    users_deleted = 0
    for uid in student_uids:
        try:
            db.collection('users').document(uid).delete()
            users_deleted += 1
        except Exception as e:
            print(f"   ⚠️  Failed to delete user {uid}: {e}")
    print(f"   ✅ Deleted {users_deleted} user documents")
    
    # 4. Delete all student_profiles
    print("\n📝 Step 4: Deleting all student_profiles...")
    profiles = db.collection('student_profiles').stream()
    profile_count = 0
    for prof in profiles:
        prof.reference.delete()
        profile_count += 1
    print(f"   ✅ Deleted {profile_count} student profiles")
    
    # 5. Delete all applications
    print("\n📄 Step 5: Deleting all scholarship applications...")
    apps = db.collection('applications').stream()
    app_count = 0
    for app in apps:
        app.reference.delete()
        app_count += 1
    print(f"   ✅ Deleted {app_count} applications")
    
    # 6. Delete all grievances
    print("\n⚠️  Step 6: Deleting all grievances...")
    grievances = db.collection('grievances').stream()
    grievance_count = 0
    for griev in grievances:
        griev.reference.delete()
        grievance_count += 1
    print(f"   ✅ Deleted {grievance_count} grievances")
    
    # 7. Delete all academic_info
    print("\n📚 Step 7: Deleting all academic_info...")
    academics = db.collection('academic_info').stream()
    academic_count = 0
    for acad in academics:
        acad.reference.delete()
        academic_count += 1
    print(f"   ✅ Deleted {academic_count} academic info records")
    
    # 8. Delete all documents_meta
    print("\n📎 Step 8: Deleting all documents_meta...")
    docs_meta = db.collection('documents_meta').stream()
    docs_count = 0
    for doc in docs_meta:
        doc.reference.delete()
        docs_count += 1
    print(f"   ✅ Deleted {docs_count} document metadata records")
    
    # Summary
    print("\n" + "=" * 80)
    print("🎉 DELETION COMPLETE!")
    print("=" * 80)
    print(f"\nDeleted:")
    print(f"  • {auth_deleted} Firebase Auth users")
    print(f"  • {users_deleted} user collection documents")
    print(f"  • {profile_count} student profiles")
    print(f"  • {app_count} scholarship applications")
    print(f"  • {grievance_count} grievances")
    print(f"  • {academic_count} academic info records")
    print(f"  • {docs_count} document metadata records")
    print("\n✅ All student data has been removed from the database.")
    print("=" * 80)

if __name__ == "__main__":
    delete_all_student_data()
