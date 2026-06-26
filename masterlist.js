const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const fs = require('fs');
const csv = require('csv-parser');

const serviceAccount = require('./firestore-uploader/serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();
const COLLECTION_NAME = 'master_list';

// CHANGE THIS to 'master_list.csv' or 'master_list.json' depending on your file!
const FILE_PATH = './firestore-uploader/master_list.csv';

/**
 * Pushes an array of item objects to Firestore using batched writes
 */
async function uploadToFirestore(items) {
  if (items.length === 0) {
    console.log('No data found to upload.');
    return;
  }

  console.log(`Starting upload of ${items.length} items to the "${COLLECTION_NAME}" collection...`);

  // Firestore batches are limited to 500 operations per batch
  const BATCH_LIMIT = 500;
  let batch = db.batch();
  let count = 0;

  for (const item of items) {
    const refNum = String(item.ReferenceNumber || '').trim();

    if (!refNum) {
      console.warn(`⚠️ Skipping item without a valid reference number:`, item);
      continue;
    }

    // Map fields cleanly to match your Flutter app data structure
    const docData = {
      name: String(item.Name || 'Unnamed Item').trim(),
      refNum: refNum,
      category: String(item.Category || 'General').trim(),
      quantity: parseInt(item.Quantity) || 0,
      minLimit: String(item.minLimit || '10'),
      status: 'In stock',
      isIncrement: true,
      timestamp: FieldValue.serverTimestamp()
    };

    // Calculate dynamic status based on incoming quantity parameters
    const rawMin = docData.minLimit.replace(/[^0-9]/g, '');
    const minQty = parseInt(rawMin) || 10;
    if (docData.quantity === 0) docData.status = 'Out of Stock';
    else if (docData.quantity < minQty) docData.status = 'Low Stock';

    // Set document using the barcode as the strict unique Document ID
    const docRef = db.collection(COLLECTION_NAME).doc(refNum);
    batch.set(docRef, docData);

    count++;

    // If batch reaches 500, commit it and start a new one
    if (count % BATCH_LIMIT === 0) {
      await batch.commit();
      console.log(`✅ Progress: Committed ${count} records...`);
      batch = db.batch();
    }
  }

  // Commit any remaining documents left in the final batch
  if (count % BATCH_LIMIT !== 0) {
    await batch.commit();
  }

  console.log(`\n🎉 Success! Successfully uploaded ${count} items to Firestore.`);
  process.exit(0);
}

/**
 * File Parsers Gateway
 */
function run() {
  if (FILE_PATH.endsWith('.json')) {
    // Handle JSON Parsing
    try {
      const rawData = fs.readFileSync(FILE_PATH, 'utf8');
      const jsonData = JSON.parse(rawData);
      // Ensure it handles both an array of objects or an enveloped payload object
      const itemsArray = Array.isArray(jsonData) ? jsonData : (jsonData.items || []);
      uploadToFirestore(itemsArray);
    } catch (error) {
      console.error('❌ Error parsing JSON file:', error.message);
    }
  } else if (FILE_PATH.endsWith('.csv')) {
    // Handle CSV Parsing
    const results = [];
    fs.createReadStream(FILE_PATH)
      .pipe(csv({
        mapHeaders: ({ header }) => header.replace(/^\uFEFF/, '').trim()
      }))
      .on('data', (data) => results.push(data))
      .on('end', () => {
          console.log(Object.keys(results[0]));
        uploadToFirestore(results);
      })
      .on('error', (error) => {
        console.error('❌ Error reading CSV file:', error.message);
      });
  } else {
    console.error('❌ Unsupported file extension. Please use a .json or .csv data file.');
  }
}

run();