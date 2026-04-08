import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import os

# Configuration
SERVICE_ACCOUNT_KEY = '../../serviceAccountKey.json'

def initialize_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def list_users_and_roles():
    """
    Fetches all users from Firestore and lists their emails and roles
    """
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: Service account key not found: {SERVICE_ACCOUNT_KEY}")
        return

    db = initialize_firebase()
    
    print("🔍 Fetching all users from Firestore...\n")
    
    # Get all users from 'users' collection
    users_ref = db.collection('users')
    users = users_ref.stream()
    
    # Organize by role
    users_by_role = {
        'admin': [],
        'committee': [],
        'faculty': [],
        'student': []
    }
    
    total_count = 0
    for user_doc in users:
        data = user_doc.to_dict()
        email = data.get('email', 'No email')
        role = data.get('role', 'No role')
        student_uid = data.get('studentUID', '')
        
        total_count += 1
        
        if role in users_by_role:
            users_by_role[role].append({
                'uid': user_doc.id,
                'email': email,
                'studentUID': student_uid
            })
        else:
            users_by_role.setdefault('other', []).append({
                'uid': user_doc.id,
                'email': email,
                'role': role,
                'studentUID': student_uid
            })
    
    # Print summary
    print(f"📊 Total Users: {total_count}\n")
    print("=" * 80)
    
    # Print by role
    for role, users_list in users_by_role.items():
        if not users_list:
            continue
            
        print(f"\n🔸 {role.upper()} ({len(users_list)} users)")
        print("-" * 80)
        for user in users_list:
            student_info = f" | Student ID: {user['studentUID']}" if user.get('studentUID') else ""
            print(f"   • {user['email']}{student_info}")
    
    print("\n" + "=" * 80)
    print(f"\n✅ Summary:")
    print(f"   - Admins: {len(users_by_role.get('admin', []))}")
    print(f"   - Committee: {len(users_by_role.get('committee', []))}")
    print(f"   - Faculty: {len(users_by_role.get('faculty', []))}")
    print(f"   - Students: {len(users_by_role.get('student', []))}")
    if 'other' in users_by_role:
        print(f"   - Other/Unknown: {len(users_by_role['other'])}")

if __name__ == "__main__":
    list_users_and_roles()
