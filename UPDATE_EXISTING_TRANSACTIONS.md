# Update Existing Transactions with Library Name

## Issue
Transactions created before the library validation feature don't have the `libraryName` field, so they show as "Unknown Library" or don't display the library name at all.

## Solution Options

### Option 1: Manual Update in Firestore Console (Recommended for few transactions)

1. Open Firebase Console
2. Go to Firestore Database
3. Open `borrow_transactions` collection
4. For each transaction document:
   - Click on the document
   - Add field: `libraryName` (type: string)
   - Set value to the library name (e.g., "Central Library")
   - Save

### Option 2: Restart App (For new transactions)

The transaction card code is already updated to show library names. You need to:

1. **Stop the app completely** (not just hot reload)
2. Run `flutter clean`
3. Run `flutter run`
4. Create a NEW transaction
5. The new transaction will have the library name

### Option 3: Script to Update All Transactions

Create a file `update_transactions.js` and run it with Node.js:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path-to-your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateTransactions() {
  console.log('Starting transaction update...');
  
  const transactionsRef = db.collection('borrow_transactions');
  const snapshot = await transactionsRef.get();
  
  console.log(`Found ${snapshot.size} transactions`);
  
  const batch = db.batch();
  let updateCount = 0;
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    // Skip if already has libraryName
    if (data.libraryName) {
      console.log(`Transaction ${doc.id} already has libraryName: ${data.libraryName}`);
      continue;
    }
    
    // Get library name from libraryId
    if (data.libraryId) {
      try {
        const libraryDoc = await db.collection('libraries').doc(data.libraryId).get();
        if (libraryDoc.exists) {
          const libraryName = libraryDoc.data().name;
          batch.update(doc.ref, { libraryName });
          updateCount++;
          console.log(`Will update transaction ${doc.id} with library: ${libraryName}`);
        } else {
          // Library not found, set default
          batch.update(doc.ref, { libraryName: 'Unknown Library' });
          updateCount++;
          console.log(`Will update transaction ${doc.id} with default library name`);
        }
      } catch (error) {
        console.error(`Error processing transaction ${doc.id}:`, error);
      }
    }
    
    // Commit in batches of 500
    if (updateCount >= 500) {
      await batch.commit();
      console.log(`Committed batch of ${updateCount} updates`);
      updateCount = 0;
    }
  }
  
  // Commit remaining
  if (updateCount > 0) {
    await batch.commit();
    console.log(`Committed final batch of ${updateCount} updates`);
  }
  
  console.log('Transaction update complete!');
}

updateTransactions().catch(console.error);
```

Run with: `node update_transactions.js`

## Verification

After updating, the transaction cards should show:
- 📚 Library icon
- "Library: [Library Name]" in accent color
- Located between the books list and the borrowed date

## Why This Happened

The `libraryName` field was added as part of the multi-library validation feature. Transactions created before this update don't have this field in Firestore, so they default to "Unknown Library" in the model.

## For Future

All NEW transactions will automatically include the library name because:
1. The `BorrowTransaction` model requires `libraryName`
2. The `createTransaction` method passes `libraryName`
3. The repository saves it to Firestore
