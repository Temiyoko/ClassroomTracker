/**
 * sync_timetable.js
 *
 * Fetches iCal timetables from the ADE system (Université Eiffel) and updates
 * the `hasCourse` field in Firestore for each classroom.
 *
 * Setup:
 *   - Each Firestore document in the `classroom` collection may have an optional
 *     `icalResourceId` field (string). This is the ADE `resources` query param.
 *   - Run via GitHub Actions with FIREBASE_SERVICE_ACCOUNT env var set.
 *
 * iCal URL template:
 *   https://edt-consult.univ-eiffel.fr/jsp/custom/modules/plannings/anonymous_cal.jsp
 *     ?resources={icalResourceId}&projectId=1&calType=ical&nbWeeks=4&displayConfigId=8
 */

"use strict";

const admin = require("firebase-admin");
const ical = require("node-ical");

// ── Firebase init ────────────────────────────────────────────────────────────

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

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── iCal URL builder ─────────────────────────────────────────────────────────

const ICAL_BASE_URL =
  "https://edt-consult.univ-eiffel.fr/jsp/custom/modules/plannings/anonymous_cal.jsp";

function buildIcalUrl(resourceId) {
  const params = new URLSearchParams({
    resources: resourceId,
    projectId: "1",
    calType: "ical",
    nbWeeks: "4",
    displayConfigId: "8",
  });
  return `${ICAL_BASE_URL}?${params.toString()}`;
}

// ── iCal parsing ─────────────────────────────────────────────────────────────

/**
 * Returns true if any VEVENT covers the point 15 minutes from now.
 * Running at :55 and checking :55+15 = the next :10 gives a clean
 * "will there be a course in the next slot?" answer before the hour turns.
 * @param {string} url
 * @returns {Promise<boolean>}
 */
async function hasCourseNow(url) {
  let events;
  try {
    events = await ical.async.fromURL(url);
  } catch (err) {
    throw new Error(`Failed to fetch iCal from ${url}: ${err.message}`);
  }

  // Check the state 15 minutes from now (e.g. at 10:55 → check 11:10)
  const checkAt = new Date(Date.now() + 15 * 60 * 1000);

  for (const key of Object.keys(events)) {
    const ev = events[key];
    if (ev.type !== "VEVENT") continue;

    const start = ev.start instanceof Date ? ev.start : new Date(ev.start);
    const end = ev.end instanceof Date ? ev.end : new Date(ev.end);

    if (start <= checkAt && checkAt < end) {
      return true;
    }
  }

  return false;
}

// ── Sync one room ─────────────────────────────────────────────────────────────

async function syncRoom(docId, resourceId) {
  const url = buildIcalUrl(resourceId);
  let hasCourse;
  try {
    hasCourse = await hasCourseNow(url);
  } catch (err) {
    console.warn(`  ⚠️  ${docId}: ${err.message} — skipping`);
    return;
  }

  await db.collection("classroom").doc(docId).update({ hasCourse });
  console.log(`  ✓ ${docId}: hasCourse = ${hasCourse}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`🕐 Sync started at ${new Date().toISOString()}`);

  const snapshot = await db.collection("classroom").get();

  const tasks = [];
  snapshot.forEach((doc) => {
    const data = doc.data();
    if (data.icalResourceId) {
      tasks.push({ docId: doc.id, resourceId: String(data.icalResourceId) });
    }
  });

  if (tasks.length === 0) {
    console.log(
      "ℹ️  No classrooms have an `icalResourceId` field — nothing to sync.\n" +
        "   Add `icalResourceId` to each Firestore document you want synced."
    );
    return;
  }

  console.log(`📡 Syncing ${tasks.length} classroom(s)...`);

  // Process in parallel (iCal fetches are independent)
  await Promise.all(tasks.map((t) => syncRoom(t.docId, t.resourceId)));

  console.log("✅ Sync complete.");
}

main()
  .catch((err) => {
    console.error("❌ Fatal error:", err);
    process.exit(1);
  })
  .finally(() => {
    // Force exit so firebase-admin doesn't keep the process alive
    process.exit(0);
  });
