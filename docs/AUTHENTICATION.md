# Authentication Credentials

This document lists the seeded user accounts available for testing the application.

## 🔐 Default Password
**For ALL accounts below, the password is:**
`Test@123`

---

## 👨‍🏫 Faculty & Admin Roles

| Role | Email | Name |
|------|-------|------|
| **Faculty** | `faculty.member@university.edu` | Dr. Faculty Member |
| **Committee** | `committee.head@university.edu` | Head of Committee |

> **Note on Faculty Accounts:**
> When a new Faculty account is created (via Committee Portal or Registration), a corresponding `FacultyProfile` document is automatically generated in Firestore.
>
> If you are using an existing Faculty account and see incomplete data, simply **Login** to the Faculty Portal once. The system will automatically detect the missing profile and create a default one for you.

---

## 🎓 Student Accounts (Sample)
The database seeder generates 25 student accounts. Below are some examples. 

**Note:** The names are randomly generated, so check the Firestore console or the "Test Data Seeder" screen logs for exact names if `alex.smith1` doesn't work (though names come from a fixed list, the combination might vary slightly if the seed script uses random choice).

**Common Pattern:** `{firstname}.{lastname}{index}@university.edu`

| # | Email (Example) | Role |
|---|----------------|------|
| 1 | `alex.smith1@university.edu` | Student |
| 2 | `jordan.johnson2@university.edu` | Student |
| 3 | `taylor.williams3@university.edu` | Student |
| ... | ... | ... |
| 25 | `emerson.clark25@university.edu` | Student |

> **Tip:** You can log in with any of these student emails to test the Student Dashboard.
