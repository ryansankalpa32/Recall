require('dotenv').config();
const { auth } = require('../lib/src/config/firebase.js');

const UID = 'WK3SD4OliZc7EVqwCrwM91FlJ5J2';
const API_KEY = 'AIzaSyB3uJ4pvIWgiIKJvhy31v2vWNp-3fleWqw';

async function getAuthToken() {
  try {
    console.log('Generating custom token for UID:', UID);
    const customToken = await auth.createCustomToken(UID);
    
    console.log('Exchanging custom token for ID token...');
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: customToken,
        returnSecureToken: true
      })
    });
    
    const data = await response.json();
    if (data.error) {
      console.error('Error fetching ID token:', data.error);
      return;
    }

    console.log("\n================ AUTH TOKEN ================");
    console.log(data.idToken);
    console.log("============================================\n");
    process.exit(0);
  } catch (err) {
    console.error('Failed:', err);
    process.exit(1);
  }
}

getAuthToken();
