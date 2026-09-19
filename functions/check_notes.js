const admin = require("firebase-admin");

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
admin.initializeApp({ projectId: "recall-cfeb3" });

async function checkNotes() {
  const db = admin.firestore();
  const usersRef = db.collection("users");
  const usersSnapshot = await usersRef.get();
  
  if (usersSnapshot.empty) {
    console.log("No users found in Firestore.");
    return;
  }
  
  console.log(`Found ${usersSnapshot.size} user(s).`);
  for (const userDoc of usersSnapshot.docs) {
    console.log(`\nUser ID: ${userDoc.id}`);
    const notesRef = userDoc.ref.collection("notes");
    const notesSnapshot = await notesRef.get();
    
    if (notesSnapshot.empty) {
      console.log("  No notes found for this user.");
    } else {
      console.log(`  Found ${notesSnapshot.size} note(s):`);
      notesSnapshot.forEach(noteDoc => {
        console.log(`  - Note ID: ${noteDoc.id}`);
        console.log(`    Data: ${JSON.stringify(noteDoc.data(), null, 2)}`);
      });
    }
  }
}

checkNotes().catch(console.error);
