import { initializeApp, cert, ServiceAccount } from "firebase-admin/app";
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
  // The server only *verifies* Firebase ID tokens, which needs just the
  // project ID (tokens are checked against Google's public keys), so no
  // service account is required on the host. FIREBASE_SERVICE_ACCOUNT_PATH
  // is still honoured for local tools that mint tokens (scratch/getToken.js).
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath) {
    const absolutePath = path.resolve(serviceAccountPath);
    const serviceAccount = JSON.parse(
      fs.readFileSync(absolutePath, "utf8"),
    ) as ServiceAccount;

    initializeApp({ credential: cert(serviceAccount) });
    console.log("[Firebase] Initialized with service account");
  } else {
    initializeApp({ projectId });
    console.log(`[Firebase] Initialized for project ${projectId}`);
  }
}

export const auth = getAuth();
