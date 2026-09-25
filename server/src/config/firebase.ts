import { initializeApp, cert, ServiceAccount } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getAuth } from "firebase-admin/auth";
import * as fs from "fs";
import * as path from "path";

const useEmulator = process.env.USE_FIREBASE_EMULATOR === "true";
const projectId = process.env.FIREBASE_PROJECT_ID || "recall-cfeb3";

if (useEmulator) {
  // Point the Admin SDK at the local emulators. These env vars must be set
  // BEFORE the first Firestore/Auth call — after that they're ignored.
  process.env.FIRESTORE_EMULATOR_HOST =
    process.env.FIRESTORE_EMULATOR_HOST || "localhost:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST =
    process.env.FIREBASE_AUTH_EMULATOR_HOST || "localhost:9099";

  initializeApp({ projectId });

  console.log(`[Firebase] Initialized with emulators (project: ${projectId})`);
  console.log(
    `[Firebase] Firestore emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`,
  );
  console.log(
    `[Firebase] Auth emulator: ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`,
  );
} else {
  // Production: use a service account JSON file or Application Default
  // Credentials (GOOGLE_APPLICATION_CREDENTIALS env var).
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath) {
    const absolutePath = path.resolve(serviceAccountPath);
    const serviceAccount = JSON.parse(
      fs.readFileSync(absolutePath, "utf8"),
    ) as ServiceAccount;

    initializeApp({ credential: cert(serviceAccount) });
    console.log("[Firebase] Initialized with service account");
  } else {
    // Falls back to GOOGLE_APPLICATION_CREDENTIALS or metadata server
    initializeApp({ projectId });
    console.log("[Firebase] Initialized with default credentials");
  }
}

export const db = getFirestore();
export const messaging = getMessaging();
export const auth = getAuth();
