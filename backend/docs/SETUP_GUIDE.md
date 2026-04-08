# Certificate Verification System - Setup Guide

## 🚀 Quick Start

### Backend Setup

1. **Navigate to backend**:

```bash
cd backend
```

2. **Install dependencies**:

```bash
npm install
```

3. **Generate RSA keys**:

```bash
node scripts/generateKeys.js
```

4. **Configure environment**:

- Copy `.env.example` to `.env`
- Update database credentials
- Paste the generated RSA keys

5. **Setup PostgreSQL** (if using free Railway.app):

- Create account at https://railway.app
- Create new project
- Add PostgreSQL service
- Copy connection details to `.env`

6. **Start server**:

```bash
npm run dev
```

Server will run on `http://localhost:3000`

---

### Flutter App Setup

1. **Update API endpoint**:

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL/api';
// For local testing: 'http://localhost:3000/api'
// For Android emulator: 'http://10.0.2.2:3000/api'
```

2. **Get dependencies**:

```bash
flutter pub get
```

3. **Run app**:

```bash
flutter run
```

---

## 📱 Using the System

### For Students

1. **View Certificates**:
   - Navigate to Profile → My Certificates
   - See all issued certificates
   - Tap to view details and QR code

2. **Verify Certificate**:
   - Use certificate ID to verify online
   - QR code can be scanned for instant verification

### For Faculty/Committee

1. **Login to get JWT token**:
   - App automatically generates token on Firebase login

2. **Generate Certificate**:
   - Use the certificate generation endpoint
   - Requires: student info + CGPA/SGPA

3. **Publish Results**:
   - Use secure backend endpoint
   - Prevents client-side tampering

---

## 🔐 Security Features

✅ **Digital Signatures**: RSA-2048 bit encryption  
✅ **Hash Verification**: SHA-256 certificate hashing  
✅ **JWT Authentication**: Secure API access  
✅ **Role-Based Access**: Admin/Faculty/Student permissions  
✅ **Tamper Prevention**: Server-side validation

---

## 🐛 Troubleshooting

### Backend won't start?

- Check PostgreSQL is running
- Verify `.env` configuration
- Ensure port 3000 is available

### Flutter connection errors?

- Verify backend URL in `api_service.dart`
- For Android emulator, use `10.0.2.2:3000`
- For physical device, use computer's IP address

### Certificate generation fails?

- Ensure user has `faculty` or `committee` role
- Check JWT token is valid
- Verify all required fields are provided

---

## 📚 API Documentation

### Authentication

**POST** `/api/auth/login`

```json
{
  "firebase_uid": "string",
  "email": "string",
  "role": "student|faculty|committee|admin",
  "student_uid": "string (optional)"
}
```

### Certificates

**POST** `/api/certificates/generate` (Auth required)

```json
{
  "student_uid": "string",
  "student_name": "string",
  "student_id": "string",
  "course": "string",
  "semester": "string",
  "cgpa": number,
  "sgpa": number
}
```

**GET** `/api/certificates/verify/:certificate_id` (Public)

Returns verification status and certificate details.

---

## 🌐 Deployment

### Free Options

1. **Railway.app**:
   - Sign up at https://railway.app
   - Connect GitHub repo
   - Add PostgreSQL service
   - Deploy automatically

2. **Render.com**:
   - Create Web Service
   - Link repo
   - Add PostgreSQL database
   - Deploy

3. **Fly.io**:
   - Install Fly CLI
   - Run `fly launch`
   - Add PostgreSQL cluster
   - Deploy with `fly deploy`

### Update Flutter app with deployed URL:

```dart
// api_service.dart
static const String baseUrl = 'https://your-app.railway.app/api';
```

---

## ✅ Next Steps

1. ☑ Set up PostgreSQL database
2. ☑ Generate and configure RSA keys
3. ☑ Test backend locally
4. ☑ Test Flutter connection
5. ☐ Deploy backend to Railway/Render
6. ☐ Update Flutter app with production URL
7. ☐ Test end-to-end certificate flow
