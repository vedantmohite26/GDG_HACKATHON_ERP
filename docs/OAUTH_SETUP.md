# OAuth Setup Guide for Google Drive Integration

This guide will walk you through setting up OAuth for Google Drive API access.

---

## Prerequisites

✅ You've created a new Firebase project  
✅ You're using the **same Google Cloud project** as Firebase

---

## Part 1: Enable Google Drive API

### Step 1: Open Google Cloud Console

1. Go to https://console.cloud.google.com/
2. **Select your project** from the dropdown at the top (same as Firebase)
   - Look for your `Student Welfare System` project

### Step 2: Enable the API

1. Click the **☰ Menu** (top left)
2. Go to **APIs & Services** → **Library**
3. In the search box, type: `Google Drive API`
4. Click on **Google Drive API** from results
5. Click the blue **ENABLE** button
6. Wait for confirmation (a few seconds)

✅ **Google Drive API is now enabled!**

---

## Part 2: Configure OAuth Consent Screen

This is what users see when they sign in to grant Google Drive permissions.

### Step 1: Access OAuth Consent Screen

1. In Google Cloud Console, click **☰ Menu**
2. Go to **APIs & Services** → **OAuth consent screen**

### Step 2: Choose User Type

- Select **External** (allows anyone with a Google account)
- Click **CREATE**

### Step 3: Fill App Information

**Page 1: OAuth consent screen**

Fill in these required fields:

| Field | What to Enter |
|-------|---------------|
| **App name** | `Student Welfare System` |
| **User support email** | Your email (select from dropdown) |
| **App logo** | (Optional - skip for now) |
| **Application home page** | (Optional - leave blank) |
| **Application privacy policy link** | (Optional - leave blank) |
| **Application terms of service link** | (Optional - leave blank) |
| **Authorized domains** | (Leave blank) |
| **Developer contact information** | Your email |

Click **SAVE AND CONTINUE**

### Step 4: Add Scopes

**Page 2: Scopes**

1. Click **ADD OR REMOVE SCOPES**
2. A panel will open on the right
3. In the **filter** box, type: `drive.file`
4. Find and **check the box** for:
   ```
   https://www.googleapis.com/auth/drive.file
   ```
   - Description: "View and manage Google Drive files and folders that you have opened or created with this app"
5. Click **UPDATE** at the bottom
6. You should see it added to the list
7. Click **SAVE AND CONTINUE**

### Step 5: Add Test Users (Optional for Development)

**Page 3: Test users**

1. Click **+ ADD USERS**
2. Enter your Gmail address (the one you'll use for testing)
3. Click **ADD**
4. Click **SAVE AND CONTINUE**

### Step 6: Summary

**Page 4: Summary**

- Review your settings
- Click **BACK TO DASHBOARD**

✅ **OAuth Consent Screen configured!**

---

## Part 3: Get SHA-1 Fingerprint

You need this for Android OAuth to work.

### For Windows (PowerShell or Command Prompt)

```bash
# Navigate to your Android debug keystore location
cd C:\Users\10323\.android

# Generate SHA-1 fingerprint
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Expected Output

Look for this section:
```
Certificate fingerprints:
         SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
         SHA256: ...
```

**Copy the SHA-1 value** (the part after `SHA1:`)

Example: `A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0`

### If the above doesn't work

Try this alternative:
```bash
# From your project directory
cd "c:\fakt projects\hack\flutter_application_1"

# Get signing report from Gradle
cd android
.\gradlew signingReport
```

Look for the **debug** variant SHA-1.

---

## Part 4: Create OAuth Client ID

### Step 1: Go to Credentials

1. In Google Cloud Console, click **☰ Menu**
2. Go to **APIs & Services** → **Credentials**
3. Click **+ CREATE CREDENTIALS** at the top
4. Select **OAuth client ID**

### Step 2: Configure Android OAuth Client

You'll see a form with these fields:

| Field | Value |
|-------|-------|
| **Application type** | Select **Android** from dropdown |
| **Name** | `Student Welfare Android` |
| **Package name** | `com.example.flutter_application_1` |
| **SHA-1 certificate fingerprint** | Paste your SHA-1 (from Part 3) |

Click **CREATE**

### Step 3: Confirmation

- You'll see a popup: "OAuth client created"
- Click **OK**
- Your OAuth client is now in the list!

---

## Part 5: Verify Setup

### Check Your Credentials

In **APIs & Services** → **Credentials**, you should see:

1. **OAuth 2.0 Client IDs**:
   - `Student Welfare Android` (Android)
   
2. **API Keys** (if any from Firebase)

### Test in Your App

When you run `flutter run` and try to upload a document:

1. **First time**: Google Sign-In popup appears
2. **You see**: "Student Welfare System wants to access your Google Account"
3. **Permissions requested**: "See, create, and delete its own files in Google Drive"
4. Click **Allow**
5. ✅ Documents will upload to your Google Drive!

---

## Troubleshooting

### "Sign-In failed" or "Error 10"

**Cause**: SHA-1 mismatch

**Solution**:
1. Double-check SHA-1 fingerprint
2. Regenerate it using `keytool` command
3. Update in OAuth client credentials
4. Wait 5-10 minutes for Google to propagate changes
5. Uninstall app from device and reinstall

### "Access blocked: Student Welfare System hasn't completed the verification process"

**Cause**: App is in testing mode

**Solution**: This is NORMAL for development!
- Add your email as a test user (Part 2, Step 5)
- Use that email to sign in
- For production, you'd need to verify the app (not needed for hackathon)

### "Invalid client" error

**Cause**: Package name mismatch

**Solution**: Ensure `com.example.flutter_application_1` matches in:
- OAuth client credentials
- `android/app/build.gradle.kts` (`applicationId`)

### "Consent screen not configured"

**Solution**: Complete Part 2 again, making sure to:
- Add the Drive scope
- Save each page

---

## Summary Checklist

Before running your app, verify:

- [ ] ✅ Google Drive API enabled
- [ ] ✅ OAuth consent screen configured
- [ ] ✅ Drive scope added: `https://www.googleapis.com/auth/drive.file`
- [ ] ✅ Test user added (your email)
- [ ] ✅ SHA-1 fingerprint obtained
- [ ] ✅ Android OAuth client created with correct package name and SHA-1
- [ ] ✅ Firebase project setup complete (from QUICKSTART.md)

---

## Next Steps

Once OAuth is set up:

1. Run your app: `flutter run`
2. Navigate to a screen with document upload
3. First upload will trigger Google Sign-In
4. Grant permissions
5. Check your Google Drive for the created folders!

**You're ready to demo! 🚀**

---

## Quick Reference

**Google Cloud Console**: https://console.cloud.google.com/  
**OAuth Consent Screen**: APIs & Services → OAuth consent screen  
**Credentials**: APIs & Services → Credentials  
**API Library**: APIs & Services → Library  

**Package Name**: `com.example.flutter_application_1`  
**Drive Scope**: `https://www.googleapis.com/auth/drive.file`  
**Keystore Location**: `C:\Users\10323\.android\debug.keystore`
