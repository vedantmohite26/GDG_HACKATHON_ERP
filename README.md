# Academic Welfare System 🎓

A comprehensive digital platform designed to streamline student welfare services, scholarship applications, and academic tracking.

## 🚀 Overview

The Academic Welfare System is a multi-platform solution that connects students, faculty, and administrative committees. It simplifies the process of applying for scholarships, grievances, and welfare programs while providing administrators with a robust dashboard for oversight.

### Key Features

*   **Student Portal**: Track academic performance, apply for scholarships, and submit welfare grievances.
*   **Faculty Interface**: Review student applications, approve/reject requests, and manage student attendance.
*   **Committee Dashboard**: Centralized oversight of all applications, statistical analysis, and institutional decisions.
*   **Secure Infrastructure**: Built with Firebase Authentication and tailored security rules.
*   **Cloud Document Support**: Seamless integration with Cloudinary for student document uploads.

## 🛠️ Tech Stack

*   **Frontend**: [Flutter](https://flutter.dev/) (Cross-platform)
*   **Backend**: [Node.js](https://nodejs.org/) & [Express](https://expressjs.com/)
*   **Database**: [Google Cloud Firestore](https://firebase.google.com/products/firestore) & [PostgreSQL](https://www.postgresql.org/)
*   **Storage**: [Firebase Storage](https://firebase.google.com/products/storage) & [Cloudinary](https://cloudinary.com/)
*   **Authentication**: [Firebase Auth](https://firebase.google.com/products/auth)

## ⚙️ Setup Instructions

### Prerequisites
- Flutter SDK
- Node.js & npm
- Firebase Project

### Local Development

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/yourusername/academic-welfare-system.git
    cd academic-welfare-system
    ```

2.  **Configuration**:
    - Place your `google-services.json` in `android/app/`.
    - Place your `GoogleService-Info.plist` in `ios/Runner/`.
    - Create a `.env` file in the `backend/` directory based on `.env.example`.

3.  **Install Dependencies**:
    ```bash
    flutter pub get
    cd backend && npm install
    ```

4.  **Run the App**:
    ```bash
    flutter run
    ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Built for the GDG Hackathon by Vedant Mohite.*
