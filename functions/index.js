const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Callable function to completely delete a faculty member
 * Deletes:
 * 1. Firebase Auth user
 * 2. Firestore 'users' document
 * 3. Firestore 'faculty_profiles' document
 * 4. Unassigns from applications and grievances
 * 
 * Can only be called by Admin or Committee members
 */
exports.deleteFacultyComplete = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to delete faculty.'
        );
    }

    const callerUID = context.auth.uid;
    const callerDoc = await admin.firestore().collection('users').doc(callerUID).get();
    const callerRole = callerDoc.data()?.role;

    if (callerRole !== 'admin' && callerRole !== 'committee') {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only Admin or Committee members can delete faculty.'
        );
    }

    const { uid } = data;

    if (!uid) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Faculty UID is required.'
        );
    }

    try {
        // 1. Delete from Firebase Auth
        try {
            await admin.auth().deleteUser(uid);
            console.log(`✅ Deleted Auth user: ${uid}`);
        } catch (authError) {
            console.warn(`⚠️ Auth user not found: ${uid}`, authError.message);
        }

        // 2. Delete from Firestore 'users' collection
        await admin.firestore().collection('users').doc(uid).delete();
        console.log(`✅ Deleted users document: ${uid}`);

        // 3. Delete from Firestore 'faculty_profiles' collection
        await admin.firestore().collection('faculty_profiles').doc(uid).delete();
        console.log(`✅ Deleted faculty_profiles document: ${uid}`);

        // 4. Unassign from applications
        const appsSnapshot = await admin.firestore()
            .collection('applications')
            .where('assignedFacultyId', '==', uid)
            .get();
        const batch1 = admin.firestore().batch();
        appsSnapshot.forEach(doc => {
            batch1.update(doc.ref, {
                assignedFacultyId: null,
                facultyComments: 'Faculty member removed',
            });
        });
        if (!appsSnapshot.empty) await batch1.commit();

        // 5. Unassign from grievances
        const grievancesSnapshot = await admin.firestore()
            .collection('grievances')
            .where('assignedTo', '==', uid)
            .get();
        const batch2 = admin.firestore().batch();
        grievancesSnapshot.forEach(doc => {
            batch2.update(doc.ref, {
                assignedTo: null,
                status: 'pending',
                internalNotes: 'Reassign - previous faculty removed',
            });
        });
        if (!grievancesSnapshot.empty) await batch2.commit();

        return {
            success: true,
            message: `Faculty member ${uid} has been completely deleted.`
        };
    } catch (error) {
        console.error('Error deleting faculty:', error);
        throw new functions.https.HttpsError(
            'internal',
            `Failed to delete faculty: ${error.message}`
        );
    }
});

/**
 * Callable function to completely delete a student
 * Deletes:
 * 1. Firebase Auth user
 * 2. Firestore 'users' document
 * 3. Firestore 'student_profiles' document
 * 4. Firestore 'academic_info' document
 * 5. Firestore 'applications' documents
 * 6. Firestore 'documents_meta' documents
 * 7. Firestore 'grievances' documents
 * 
 * Can only be called by Admin or Committee members
 */
exports.deleteStudentComplete = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            'unauthenticated',
            'User must be authenticated to delete students.'
        );
    }

    const callerUID = context.auth.uid;
    const callerDoc = await admin.firestore().collection('users').doc(callerUID).get();
    const callerRole = callerDoc.data()?.role;

    if (callerRole !== 'admin' && callerRole !== 'committee') {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only Admin or Committee members can delete students.'
        );
    }

    const { uid, studentId } = data;

    if (!uid && !studentId) {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'Either student UID or studentId is required.'
        );
    }

    try {
        let authUid = uid;
        let studentUID = studentId;

        // If we have the auth UID, find the studentUID from the users collection
        if (authUid && !studentUID) {
            const userDoc = await admin.firestore().collection('users').doc(authUid).get();
            if (userDoc.exists) {
                studentUID = userDoc.data()?.studentUID;
            }
        }

        // If we have studentId but no auth UID, find it from student_profiles
        if (studentUID && !authUid) {
            const profileDoc = await admin.firestore().collection('student_profiles').doc(studentUID).get();
            if (profileDoc.exists) {
                authUid = profileDoc.data()?.userId;
            }
        }

        // 1. Delete from Firebase Auth
        if (authUid) {
            try {
                await admin.auth().deleteUser(authUid);
                console.log(`✅ Deleted Auth user: ${authUid}`);
            } catch (authError) {
                console.warn(`⚠️ Auth user not found: ${authUid}`, authError.message);
            }

            // 2. Delete from Firestore 'users' collection
            await admin.firestore().collection('users').doc(authUid).delete();
            console.log(`✅ Deleted users document: ${authUid}`);
        }

        if (studentUID) {
            // 3. Delete from Firestore 'student_profiles'
            await admin.firestore().collection('student_profiles').doc(studentUID).delete();
            console.log(`✅ Deleted student_profiles: ${studentUID}`);

            // 4. Delete academic_info
            await admin.firestore().collection('academic_info').doc(studentUID).delete();
            console.log(`✅ Deleted academic_info: ${studentUID}`);

            // 5. Delete applications
            const appsSnapshot = await admin.firestore()
                .collection('applications')
                .where('studentUID', '==', studentUID)
                .get();
            const batch1 = admin.firestore().batch();
            appsSnapshot.forEach(doc => batch1.delete(doc.ref));
            if (!appsSnapshot.empty) {
                await batch1.commit();
                console.log(`✅ Deleted ${appsSnapshot.size} applications`);
            }

            // 6. Delete documents_meta
            const docsSnapshot = await admin.firestore()
                .collection('documents_meta')
                .where('studentUID', '==', studentUID)
                .get();
            const batch2 = admin.firestore().batch();
            docsSnapshot.forEach(doc => batch2.delete(doc.ref));
            if (!docsSnapshot.empty) {
                await batch2.commit();
                console.log(`✅ Deleted ${docsSnapshot.size} documents_meta`);
            }
        }

        // 7. Delete grievances (tied to authUid)
        if (authUid) {
            const grievancesSnapshot = await admin.firestore()
                .collection('grievances')
                .where('userId', '==', authUid)
                .get();
            const batch3 = admin.firestore().batch();
            grievancesSnapshot.forEach(doc => batch3.delete(doc.ref));
            if (!grievancesSnapshot.empty) {
                await batch3.commit();
                console.log(`✅ Deleted ${grievancesSnapshot.size} grievances`);
            }
        }

        return {
            success: true,
            message: `Student ${studentUID || authUid} has been completely deleted.`
        };
    } catch (error) {
        console.error('Error deleting student:', error);
        throw new functions.https.HttpsError(
            'internal',
            `Failed to delete student: ${error.message}`
        );
    }
});
