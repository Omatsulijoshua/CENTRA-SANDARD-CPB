import { initializeApp, getApps } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

console.log('Firebase Config:', firebaseConfig);
const isConfigValid = !!firebaseConfig.apiKey && firebaseConfig.apiKey !== '""' && firebaseConfig.apiKey !== '';
console.log('Is Config Valid:', isConfigValid);

let app
let auth
let db
let storage

if (isConfigValid) {
  try {
    app = getApps().length ? getApps()[0] : initializeApp(firebaseConfig)
    auth = getAuth(app)
    db = getFirestore(app)
    storage = getStorage(app)
  } catch (err) {
    console.error('Firebase initialization failed:', err)
  }
} else {
  console.warn('Firebase configuration is missing or invalid. Dashboard will be in restricted mode.')
}

export { auth, db, storage, isConfigValid }
