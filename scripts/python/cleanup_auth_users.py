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

def cleanup_orphaned_auth_users():
    """
    Finds and deletes Firebase Auth users that don't have a corresponding
    'users' document in Firestore (orphaned accounts from deleted faculty).
    
    Run this script periodically (e.g., weekly) to clean up Auth users.
    """
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    
    print("🔍 Scanning for orphaned Auth users...")
    
    # Get all Auth users
    page = auth.list_users()
    all_auth_users = []
    while page:
        all_auth_users.extend(page.users)
        page = page.get_next_page()
    
    print(f"📊 Found {len(all_auth_users)} total Auth users")
    
    # Get all Firestore user UIDs
    users_ref = db.collection('users')
    firestore_users = {doc.id for doc in users_ref.stream()}
    
    print(f"📊 Found {len(firestore_users)} Firestore user documents")
    
    # Find orphaned users
    orphaned = []
    for user in all_auth_users:
        if user.uid not in firestore_users:
            orphaned.append(user)
    
    if not orphaned:
        print("✅ No orphaned Auth users found!")
        return
    
    print(f"\n⚠️  Found {len(orphaned)} orphaned Auth users:")
    for user in orphaned:
        print(f"   • {user.email} (UID: {user.uid})")
    
    # Ask for confirmation
    response = input(f"\n❓ Delete these {len(orphaned)} orphaned Auth users? (yes/no): ")
    
    if response.lower() != 'yes':
        print("❌ Cancelled. No users were deleted.")
        return
    
    # Delete orphaned users
    deleted_count = 0
    for user in orphaned:
        try:
            auth.delete_user(user.uid)
            print(f"✅ Deleted: {user.email} ({user.uid})")
            deleted_count += 1
        except Exception as e:
            print(f"❌ Failed to delete {user.email}: {e}")
    
    print(f"\n🎉 Cleanup complete! Deleted {deleted_count}/{len(orphaned)} orphaned users.")

if __name__ == "__main__":
    cleanup_orphaned_auth_users()
