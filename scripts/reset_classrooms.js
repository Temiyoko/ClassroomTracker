/**
 * reset_classrooms.js
 *
 * Resets all classrooms at the start of each day:
 *   currentPeople = 0
 *   hasCourse     = false
 *
 * Run via GitHub Actions every weekday morning before classes start.
 */

"use strict";

const admin = require("firebase-admin");

// ── Firebase init ─────────────────────────────────────────────────────────────

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountJson) {
  console.error("❌ FIREBASE_SERVICE_ACCOUNT env var is not set.");
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(serviceAccountJson);
} catch (e) {
  console.error("❌ Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:", e.message);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Reset ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`🔄 Daily reset started at ${new Date().toISOString()}`);

  const snapshot = await db.collection("classroom").get();
  const BATCH_SIZE = 400;
  const docs = snapshot.docs;
  let count = 0;

  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    docs.slice(i, i + BATCH_SIZE).forEach((doc) => {
      batch.update(doc.ref, { currentPeople: 0, hasCourse: false });
      count++;
    });
    await batch.commit();
  }

  console.log(`✅ Reset ${count} classroom(s).`);
}

main()
  .catch((err) => {
    console.error("❌ Fatal error:", err);
    process.exit(1);
  })
  .finally(() => process.exit(0));
