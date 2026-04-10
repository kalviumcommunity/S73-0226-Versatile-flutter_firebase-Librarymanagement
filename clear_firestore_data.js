# 🧹 COMPLETE FIREBASE DATA CLEARING GUIDE
# Project ID: lib-management-d6460

# STEP 1: Login to Firebase CLI
firebase login

# STEP 2: Clear ALL Firestore Collections (Complete Fresh Start)
firebase firestore:delete --all-collections --force --project lib-management-d6460

# STEP 3: Clear Firebase Authentication Users (Optional but recommended for complete fresh start)
# Go to Firebase Console: https://console.firebase.google.com/project/lib-management-d6460/authentication/users
# Click "Delete all users" or delete individually

# ALTERNATIVE: Clear Individual Collections (if you want to keep some data)
# firebase firestore:delete access_tokens --recursive --force --project lib-management-d6460
# firebase firestore:delete books --recursive --force --project lib-management-d6460
# firebase firestore:delete borrow_transactions --recursive --force --project lib-management-d6460
# firebase firestore:delete borrows --recursive --force --project lib-management-d6460
# firebase firestore:delete libraries --recursive --force --project lib-management-d6460
# firebase firestore:delete library_members --recursive --force --project lib-management-d6460
# firebase firestore:delete reservations --recursive --force --project lib-management-d6460
# firebase firestore:delete users --recursive --force --project lib-management-d6460

# OPTION 2: Using Firebase Console (Web Interface)
# 1. Go to https://console.firebase.google.com/
# 2. Select your project
# 3. Go to Firestore Database
# 4. Delete collections manually by clicking on each collection and selecting "Delete collection"

# OPTION 3: Node.js Script (if you have service account key)
# Uncomment and modify the following if you want to use Node.js approach:

/*
const admin = require('firebase-admin');

// You need to download service account key from Firebase Console
// Go to Project Settings > Service Accounts > Generate new private key
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function clearCollection(collectionName) {
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  if (snapshot.empty) {
    console.log(`Collection ${collectionName} is already empty`);
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Cleared ${snapshot.size} documents from ${collectionName}`);
}

async function clearAllData() {
  try {
    console.log('🧹 Starting to clear Firestore data...');
    
    // Clear all collections except users (keep authentication)
    await clearCollection('books');
    await clearCollection('reservations');
    await clearCollection('borrow_transactions');
    await clearCollection('libraries');
    await clearCollection('library_members');
    
    console.log('✅ All data cleared successfully!');
    console.log('📝 Note: Users collection kept for authentication');
    
  } catch (error) {
    console.error('❌ Error clearing data:', error);
  }
}

clearAllData();
*/