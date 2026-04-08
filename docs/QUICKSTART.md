# 🚀 Quick Start Guide - Student Welfare System

Follow these steps to get your app running for the hackathon!

---

## Step 1: Add Android App to Firebase

1. Go to your Firebase project: https://console.firebase.google.com/
2. Click the **Android icon** (⚙️ Settings → Your apps → Add app)
3. **Package name**: `com.example.flutter_application_1`
4. **App nickname**: `Student Welfare Android` (optional)
5. Click **Register app**
6. **Download** `google-services.json`
7. **Place it** in `android/app/` folder (replace the old one if exists)
8. Click **Next** → **Next** → **Continue to console**

---

## Step 2: Update Firebase Configuration

Once you have the new `google-services.json`:

**Tell me and I'll generate the new `firebase_options.dart` for you!** Just say:
> "I've added the new google-services.json, please update firebase_options.dart"

Or do it manually by viewing the file and copying the values.

---

## Step 3: Enable Firebase Services

### Enable Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get Started**
3. Click **Sign-in method** tab
4. Click **Email/Password**
5. Toggle **Enable**
6. Click **Save**

### Enable Firestore Database

1. Go to **Build** → **Firestore Database**
2. Click **Create database**
3. **Start in test mode** (we'll add rules later)
4. Choose location: **asia-south1** (or closest to you)
5. Click **Enable**

---

## Step 4: Deploy Firestore Security Rules

1. In Firebase Console, go to **Firestore Database** → **Rules**
2. **Copy ALL content** from your local file: `firestore.rules`
3. **Paste** into the Firebase Console rules editor
4. Click **Publish**

**Important**: These rules enforce role-based access control!

---

## Step 5: Google Drive API Setup

### Enable Google Drive API

1. Go to https://console.cloud.google.com/
2. **Select the SAME project** as Firebase (top dropdown)
3. Click **☰ Menu** → **APIs & Services** → **Library**
4. Search: `Google Drive API`
5. Click on it → Click **Enable**

### Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External**
3. Fill in:
   - App name: `Student Welfare System`
   - User support email: (your email)
   - Developer contact: (your email)
4. Click **Save and Continue**
5. **Scopes**: Click **Add or Remove Scopes**
   - Search and add: `https://www.googleapis.com/auth/drive.file`
   - Click **Update** → **Save and Continue**
6. **Test users**: Add your email
7. Click **Save and Continue** → **Back to Dashboard**

### Get SHA-1 Fingerprint (for Android)

**Windows**:
```bash
cd C:\Users\10323\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Copy the SHA-1 value** (looks like: `A1:B2:C3:D4:...`)

### Create OAuth Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. Application type: **Android**
4. Name: `Android Client`
5. **Package name**: `com.example.flutter_application_1`
6. **SHA-1 certificate fingerprint**: (paste your SHA-1)
7. Click **Create**

---

## Step 6: Run the App

```bash
# Make sure you're in the project directory
cd c:\fakt projects\hack\flutter_application_1

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## Step 7: Test the App

### Register First User

1. App opens to **Login screen**
2. Click **"Don't have an account? Register"**
3. Fill in:
   - Student UID: `TEST001`
   - Email: `student@test.com`
   - Role: **Student**
   - Password: `student123`
4. Click **Register**
5. You'll be redirected to login
6. **Login** with the same credentials

### What You Should See

✅ Login successful  
✅ Redirected to **Student Dashboard**  
✅ See welcome message and quick action cards

---

## Step 8: Upload Test Document (Google Drive)

1. On first document upload, **Google Sign-In** popup will appear
2. Sign in with your Google account
3. Grant **Drive permissions**
4. Upload a test PDF/image
5. **Check your Google Drive**:
   - Open https://drive.google.com
   - Look for folder: **"Student Welfare - Documents"**
   - Inside: **"TEST001"** folder with your uploaded file!

🎉 **Perfect for demo to judges!**

---

## Troubleshooting

### "Failed to initialize Firebase"
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean` then `flutter pub get`

### "Google Sign-In failed"
- Verify SHA-1 fingerprint is correct
- Check OAuth consent screen is configured
- Ensure you enabled Google Drive API

### "Permission denied" in Firestore
- Deploy the security rules from `firestore.rules`

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

---

## Next Steps for Hackathon

- [ ] Create more test users (Admin, Committee)
- [ ] Build the student profile screen
- [ ] Add document upload UI
- [ ] Create scholarship listing screen
- [ ] Test grievance submission

See `task.md` for complete feature checklist!

---

## Demo Tips for Judges

1. **Show Google Drive Integration**:
   - Upload document in app
   - Switch to Google Drive browser tab
   - Show the auto-created folder structure

2. **Highlight FREE Tech Stack**:
   - "We're using Firebase FREE tier for auth and database"
   - "Google Drive gives us 15GB FREE storage"
   - "All smart features use rule-based logic, no paid AI APIs"

3. **Show Role-Based Access**:
   - Login as Student → see student features
   - Login as Admin → see management features

---

**Need help?** Refer to:
- Full setup: `README.md`
- Google Drive details: `GOOGLE_DRIVE_SETUP.md`
- Architecture: `walkthrough.md`

**You're ready to impress! 🏆**
