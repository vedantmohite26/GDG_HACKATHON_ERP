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

def delete_all_faculty_data():
    """
    ⚠️ WARNING: This will DELETE ALL faculty data from the database!
    This includes:
    - Firebase Auth users with role='faculty'
    - Firestore 'users' collection documents (faculty only)
    - Firestore 'faculty_profiles' collection documents (faculty only)
    
    Committee members and Admin will NOT be affected.
    """
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    
    print("\n" + "=" * 80)
    print("⚠️  WARNING: DESTRUCTIVE OPERATION ⚠️")
    print("=" * 80)
    print("\nThis will DELETE ALL faculty data including:")
    print("  • All faculty user accounts (Firebase Auth)")
    print("  • All faculty profiles")
    print("  • Faculty will be unassigned from applications and grievances")
    print("\nAdmin and Committee accounts will NOT be affected.")
    print("=" * 80)
    
    # Ask for confirmation
    response = input("\n❓ Are you ABSOLUTELY SURE you want to proceed? (type 'DELETE ALL FACULTY'): ")
    
    if response != 'DELETE ALL FACULTY':
        print("\n❌ Operation cancelled. No data was deleted.")
        return
    
    print("\n🗑️  Starting deletion process...\n")
    
    # 1. Get all faculty UIDs from users collection (NOT committee)
    print("📋 Step 1: Finding all faculty users...")
    faculty_users = db.collection('users').where('role', '==', 'faculty').stream()
    faculty_uids = [doc.id for doc in faculty_users]
    print(f"   Found {len(faculty_uids)} faculty users")
    
    if len(faculty_uids) == 0:
        print("\n✅ No faculty users found. Nothing to delete.")
        return
    
    # 2. Delete from Firebase Auth
    print("\n🔐 Step 2: Deleting from Firebase Auth...")
    auth_deleted = 0
    for uid in faculty_uids:
        try:
            auth.delete_user(uid)
            auth_deleted += 1
        except Exception as e:
            print(f"   ⚠️  Failed to delete Auth user {uid}: {e}")
    print(f"   ✅ Deleted {auth_deleted} Firebase Auth users")
    
    # 3. Delete from users collection
    print("\n👤 Step 3: Deleting from 'users' collection...")
    users_deleted = 0
    for uid in faculty_uids:
        try:
            db.collection('users').document(uid).delete()
            users_deleted += 1
        except Exception as e:
            print(f"   ⚠️  Failed to delete user {uid}: {e}")
    print(f"   ✅ Deleted {users_deleted} user documents")
    
    # 4. Delete faculty_profiles (only for these faculty UIDs)
    print("\n📝 Step 4: Deleting faculty_profiles...")
    profile_count = 0
    for uid in faculty_uids:
        try:
            db.collection('faculty_profiles').document(uid).delete()
            profile_count += 1
        except Exception as e:
            print(f"   ⚠️  Failed to delete profile {uid}: {e}")
    print(f"   ✅ Deleted {profile_count} faculty profiles")
    
    # 5. Unassign from applications
    print("\n📄 Step 5: Unassigning faculty from applications...")
    for uid in faculty_uids:
        apps = db.collection('applications').where('assignedFacultyId', '==', uid).stream()
        app_count = 0
        for app in apps:
            app.reference.update({
                'assignedFacultyId': None,
                'facultyComments': 'Faculty member removed'
            })
            app_count += 1
        if app_count > 0:
            print(f"   Unassigned faculty from {app_count} applications")
    
    # 6. Unassign from grievances
    print("\n⚠️  Step 6: Unassigning faculty from grievances...")
    for uid in faculty_uids:
        grievances = db.collection('grievances').where('assignedTo', '==', uid).stream()
        griev_count = 0
        for griev in grievances:
            griev.reference.update({
                'assignedTo': None,
                'status': 'pending',
                'internalNotes': 'Reassign - previous faculty removed'
            })
            griev_count += 1
        if griev_count > 0:
            print(f"   Unassigned faculty from {griev_count} grievances")
    
    # Summary
    print("\n" + "=" * 80)
    print("🎉 DELETION COMPLETE!")
    print("=" * 80)
    print(f"\nDeleted:")
    print(f"  • {auth_deleted} Firebase Auth users")
    print(f"  • {users_deleted} user collection documents")
    print(f"  • {profile_count} faculty profiles")
    print("\n✅ All faculty data has been removed from the database.")
    print("✅ Committee and Admin accounts remain safe.")
    print("=" * 80)

if __name__ == "__main__":
    delete_all_faculty_data()
