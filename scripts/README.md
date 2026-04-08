# Firebase Admin SDK Setup

## Prerequisites

1. **Get Service Account Key**:
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select project: `student-welfare-system-baa40`
   - Go to **Project Settings** (gear icon) → **Service Accounts**
   - Click "Generate new private key"
   - Save the JSON file as `serviceAccountKey.json` in the `scripts/` directory

## Setup Instructions

```bash
# Navigate to scripts directory
cd scripts

# Install dependencies
npm install

# Run setup script
npm run setup
```

## What the Script Does

1. Creates 8 user accounts in Firebase Authentication:
   - 3 Committee members (COMM001-003)
   - 5 Admin members (ADMIN001-005)

2. Creates corresponding Firestore documents in `users` collection with:
   - email
   - role (admin/committee)
   - studentUID (ID number)
   - createdAt (timestamp)

## Expected Output

```
🚀 Starting Firebase user setup...

✅ Created Auth user: member@example.com
✅ Created Firestore document for: member@example.com
   UID: abc123...
   Role: committee
   ID: COMM001

... (repeats for all users)

✅ Setup complete!

📝 Summary:
   - 3 Committee members created
   - 5 Admin members created

🔐 Login Credentials:
   Committee: member@example.com / ChangeMe2024!
   Faculty: faculty1@example.com / ChangeMe2024!
```

## Security Notes

⚠️ **IMPORTANT**:
- Keep `serviceAccountKey.json` secure and never commit it to version control
- The `.gitignore` should already exclude this file
- Delete or secure this file after setup
- All users should change their passwords after first login

## Troubleshooting

**Error: "User already exists"**
- This is normal if running the script multiple times
- The script will skip existing users

**Error: "Permission denied"**
- Ensure the service account key is valid
- Check Firebase project permissions

**Error: "Module not found"**
- Run `npm install` in the scripts directory
