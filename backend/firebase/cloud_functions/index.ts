import { onDocumentCreated } from 'firebase-functions/v2/firestore'
import admin from 'firebase-admin'

admin.initializeApp()

export const sendPaymentNotification = onDocumentCreated('transactions/{transactionId}', async (event) => {
  const data = event.data?.data()
  if (!data || data.status !== 'SUCCEEDED') return
  await admin.firestore().collection('notifications').add({
    businessId: data.businessId,
    title: 'Payment received',
    body: `NGN ${data.amount} received via ${data.channel}`,
    channel: 'PUSH',
    status: 'QUEUED',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  })
})
