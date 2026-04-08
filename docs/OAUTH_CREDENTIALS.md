# 🔐 OAuth Credentials - Student Welfare System

## Your SHA-1 Fingerprint (Android Debug)

```
B4:B9:10:B0:8B:4F:77:02:B5:64:77:95:F6:71:72:77:43:01:D3:45
```

---

## Quick Setup Steps

### 1. Go to Google Cloud Console
https://console.cloud.google.com/

**Select your Firebase project** from the dropdown

---

### 2. Enable Google Drive API

1. **☰ Menu** → **APIs & Services** → **Library**
2. Search: `Google Drive API`
3. Click **ENABLE**

---

### 3. Configure OAuth Consent Screen

1. **☰ Menu** → **APIs & Services** → **OAuth consent screen**
2. Choose **External** → **CREATE**
3. Fill in:
   - **App name**: `Student Welfare System`
   - **User support email**: (your email)
   - **Developer contact**: (your email)
4. **SAVE AND CONTINUE**
5. Click **ADD OR REMOVE SCOPES**
6. Add scope: `https://www.googleapis.com/auth/drive.file`
7. **UPDATE** → **SAVE AND CONTINUE**
8. **ADD USERS** → Add your email → **SAVE AND CONTINUE**
9. **BACK TO DASHBOARD**

---

### 4. Create OAuth Client ID (Android)

1. **☰ Menu** → **APIs & Services** → **Credentials**
2. **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Fill in:

| Field | Value |
|-------|-------|
| **Application type** | Android |
| **Name** | `Student Welfare Android` |
| **Package name** | `com.example.flutter_application_1` |
| **SHA-1 fingerprint** | `B4:B9:10:B0:8B:4F:77:02:B5:64:77:95:F6:71:72:77:43:01:D3:45` |

4. **CREATE**

---

## ✅ Checklist

- [ ] Google Drive API enabled
- [ ] OAuth consent screen configured
- [ ] Drive scope added
- [ ] Test user added (your email)
- [ ] Android OAuth client created with above SHA-1

---

## Test After Setup

1. Run: `flutter run`
2. Upload a document (when you create that feature)
3. Google Sign-In will prompt
4. Grant Drive permissions
5. Check Google Drive for "Student Welfare - Documents" folder!

---

## Package Info

**Package Name**: `com.example.flutter_application_1`  
**SHA-1**: `B4:B9:10:B0:8B:4F:77:02:B5:64:77:95:F6:71:72:77:43:01:D3:45`  
**Drive Scope**: `https://www.googleapis.com/auth/drive.file`

---

**Next**: Complete OAuth setup in Google Cloud Console, then you're ready to run the app! 🚀
