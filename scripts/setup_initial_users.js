// Firebase Admin SDK Setup Script
// This script creates initial admin and committee accounts

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

// Initial users data (PLACEHOLDERS: Replace with your actual data)
const users = [
    // Committee Members
    { email: 'committee1@example.com', password: 'ChangeMe2024!', role: 'committee', studentUID: 'COMM001' },
    { email: 'committee2@example.com', password: 'ChangeMe2024!', role: 'committee', studentUID: 'COMM002' },
    { email: 'committee3@example.com', password: 'ChangeMe2024!', role: 'committee', studentUID: 'COMM003' },

    // Student Added manually for Quick Login
    { email: 'student1@example.com', password: 'ChangeMe2024!', role: 'student', studentUID: 'STU001' },

    // Faculty Members
    { email: 'faculty1@example.com', password: 'ChangeMe2024!', role: 'faculty', studentUID: 'FAC001' },
    { email: 'faculty2@example.com', password: 'ChangeMe2024!', role: 'faculty', studentUID: 'FAC002' },
    { email: 'faculty3@example.com', password: 'ChangeMe2024!', role: 'faculty', studentUID: 'FAC003' },
];

async function setupInitialUsers() {
    console.log('🚀 Starting Firebase user setup...\n');

    for (const userData of users) {
        try {
            // Create user in Firebase Authentication
            const userRecord = await auth.createUser({
                email: userData.email,
                password: userData.password,
                emailVerified: true,
            });

            console.log(`✅ Created Auth user: ${userData.email}`);

            // Create user document in Firestore
            await db.collection('users').doc(userRecord.uid).set({
                email: userData.email,
                role: userData.role,
                studentUID: userData.studentUID,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`✅ Created Firestore document for: ${userData.email}`);
            console.log(`   UID: ${userRecord.uid}`);
            console.log(`   Role: ${userData.role}`);
            console.log(`   ID: ${userData.studentUID}\n`);

        } catch (error) {
            if (error.code === 'auth/email-already-exists') {
                console.log(`⚠️  User already exists: ${userData.email}. Updating password to match setup script...`);
                // Get the existing user
                const userRecord = await auth.getUserByEmail(userData.email);
                
                // Update password
                await auth.updateUser(userRecord.uid, {
                    password: userData.password,
                    emailVerified: true,
                });

                // Ensure Firestore document exists
                await db.collection('users').doc(userRecord.uid).set({
                    email: userData.email,
                    role: userData.role,
                    studentUID: userData.studentUID,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                
                console.log(`✅ Updated password and Firestore document for: ${userData.email}\n`);
            } else {
                console.error(`❌ Error creating ${userData.email}:`, error.message, '\n');
            }
        }
    }

    console.log('\n✅ Setup complete!');
    console.log('\n📝 Summary:');
    console.log('   - 3 Committee members created');
    console.log('   - 5 Admin members created');
    console.log('\n🔐 Login Credentials:');
    console.log('   Committee: member@example.com / ChangeMe2024!');
    console.log('   Faculty: faculty1@example.com / ChangeMe2024!');
    console.log('\n⚠️  Remember to change passwords after first login!\n');

    process.exit(0);
}

// Run the setup
setupInitialUsers().catch((error) => {
    console.error('❌ Setup failed:', error);
    process.exit(1);
});
