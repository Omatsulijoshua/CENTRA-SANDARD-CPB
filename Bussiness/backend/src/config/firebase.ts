import fs from 'node:fs'
import admin from 'firebase-admin'

export function initFirebase() {
  if (admin.apps.length) return admin.app()
  const file = process.env.FIREBASE_SERVICE_ACCOUNT_FILE
  if (file && fs.existsSync(file)) {
    const serviceAccount = JSON.parse(fs.readFileSync(file, 'utf8'))
    return admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })
  }
  return admin.initializeApp()
}

export const firebaseAdmin = initFirebase()
