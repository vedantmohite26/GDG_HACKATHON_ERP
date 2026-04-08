# UniConnect Backend API

Backend API for certificate verification and secure operations.

## Features

- 🔐 JWT Authentication
- 📜 Digital Certificate Generation & Verification
- 🔒 RSA Signature-based Security
- 🗄️ PostgreSQL Database
- ⚡ Express.js REST API

## Setup

### Prerequisites

- Node.js 16+
- PostgreSQL 14+

### Installation

1. Install dependencies:

```bash
cd backend
npm install
```

2. Configure environment:

```bash
cp .env.example .env
```

3. Generate RSA keys:

```bash
node scripts/generateKeys.js
```

4. Update `.env` with database credentials and RSA keys

5. Start the server:

```bash
npm run dev
```

## API Endpoints

### Authentication

- `POST /api/auth/login` - Login and get JWT token
- `POST /api/auth/verify` - Verify JWT token

### Certificates

- `POST /api/certificates/generate` - Generate certificate (faculty/committee)
- `GET /api/certificates/verify/:id` - Verify certificate (public)
- `GET /api/certificates/student/:uid` - Get student certificates
- `POST /api/certificates/revoke/:id` - Revoke certificate (admin)

### Results

- `POST /api/results/publish` - Publish results (faculty/committee)

## Security Features

- RSA-2048 digital signatures
- SHA-256 certificate hashing
- JWT token authentication
- Role-based access control
- Rate limiting
- CORS protection
- Helmet security headers

## Database Schema

### Certificates

- `certificate_id` (UUID, PK)
- `student_uid` (String)
- `student_name` (String)
- `course` (String)
- `semester` (String)
- `cgpa` (Float)
- `sgpa` (Float)
- `digital_signature` (Text)
- `certificate_hash` (String)
- `is_revoked` (Boolean)

## Deployment

See `docs/deployment.md` for deployment instructions.
