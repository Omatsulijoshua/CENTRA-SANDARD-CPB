const express = require('express')
const cors = require('cors')
require('dotenv').config()

const app = express()
app.use(cors())
app.use(express.json())

const useFirebase = process.env.USE_FIREBASE === '1'

if (!useFirebase) {
  app.get('/health', (req, res) => res.json({ ok: true, mode: 'legacy_disabled' }))
  app.listen(process.env.PORT || 3000, () => console.log(`Server running (legacy disabled) on ${process.env.PORT || 3000}`))
  return
}

const fs = require('fs')
const admin = require('firebase-admin')

function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
  }
  if (process.env.FIREBASE_SERVICE_ACCOUNT_FILE) {
    return JSON.parse(fs.readFileSync(process.env.FIREBASE_SERVICE_ACCOUNT_FILE, 'utf8'))
  }
  return null
}

const serviceAccount = loadServiceAccount()
if (!serviceAccount && useFirebase) {
  console.warn(
    'WARNING: Missing Firebase credentials. Firebase features will be disabled. Set FIREBASE_SERVICE_ACCOUNT_FILE or FIREBASE_SERVICE_ACCOUNT_JSON in backend/.env'
  )
} else if (serviceAccount) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
    console.log('Firebase initialized successfully')
  } catch (e) {
    console.error('Firebase initialization failed:', e.message)
  }
}

const db = admin.apps.length > 0 ? admin.firestore() : null
const auth = admin.apps.length > 0 ? admin.auth() : null

const requireFirebaseAuth = async (req, res, next) => {
  if (!serviceAccount) {
    return res.status(503).json({ error: 'Firebase service unavailable' })
  }
  const authHeader = req.headers.authorization || ''
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null
  if (!token) return res.status(401).json({ error: 'Missing Authorization Bearer token' })

  try {
    const decoded = await admin.auth().verifyIdToken(token)
    if (process.env.FIREBASE_PROJECT_ID && decoded.aud !== process.env.FIREBASE_PROJECT_ID) {
      return res.status(401).json({ error: 'Invalid token audience' })
    }
    req.user = decoded
    req.uid = decoded.uid
    next()
  } catch (e) {
    return res.status(401).json({ error: 'Invalid token' })
  }
}

const requireAdmin = async (req, res, next) => {
  try {
    const snap = await db.collection('admins').doc(req.uid).get()
    if (!snap.exists) return res.status(403).json({ error: 'Access denied. Admin only.' })
    next()
  } catch (e) {
    return res.status(500).json({ error: 'Admin check failed' })
  }
}

app.get('/health', (req, res) => res.json({ ok: true, mode: 'firebase' }))

// --- USER ROUTES (match mobile app) ---

app.get('/api/user/profile', requireFirebaseAuth, async (req, res) => {
  try {
    const snap = await db.collection('users').doc(req.uid).get()
    if (!snap.exists) return res.status(404).json({ error: 'User not found' })
    res.json({ id: snap.id, ...snap.data() })
  } catch (e) {
    res.status(500).json({ error: 'Error fetching profile' })
  }
})

app.get('/api/transactions', requireFirebaseAuth, async (req, res) => {
  try {
    const q = await db
      .collection('transactions')
      .where('userId', '==', req.uid)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching transactions' })
  }
})

app.post('/api/banks/resolve', requireFirebaseAuth, async (req, res) => {
  const { accountNumber } = req.body || {}
  if (!accountNumber || String(accountNumber).length !== 10) {
    return res.status(400).json({ error: 'Invalid account number' })
  }

  try {
    const q = await db.collection('users').where('accountNumber', '==', String(accountNumber)).limit(1).get()
    if (!q.empty) {
      const user = q.docs[0].data()
      return res.json({ accountName: user.name || '', internal: true })
    }
    // Mock external resolve (same behavior as old backend)
    const mockNames = ['Chinedu Okafor', 'Fatima Bello', 'Oluwaseun Adeyemi', 'Ngozi Eze']
    const idx = Number(String(accountNumber).slice(0, 1)) % mockNames.length
    return res.json({ accountName: mockNames[idx], internal: false })
  } catch (e) {
    return res.status(500).json({ error: 'Resolve failed' })
  }
})

app.post('/api/transactions/send', requireFirebaseAuth, async (req, res) => {
  const { receiverAccountNumber, amount } = req.body || {}
  const amt = Number(amount)
  const receiverAcct = String(receiverAccountNumber || '').trim()

  if (!receiverAcct || receiverAcct.length !== 10) return res.status(400).json({ error: 'Invalid receiver account number' })
  if (!Number.isFinite(amt) || amt <= 0) return res.status(400).json({ error: 'Invalid amount' })

  try {
    const receiverQuery = await db.collection('users').where('accountNumber', '==', receiverAcct).limit(1).get()
    if (receiverQuery.empty) return res.status(404).json({ error: 'Receiver not found' })
    const receiverUid = receiverQuery.docs[0].id
    if (receiverUid === req.uid) return res.status(400).json({ error: 'Cannot send money to yourself' })

    const senderRef = db.collection('users').doc(req.uid)
    const receiverRef = db.collection('users').doc(receiverUid)
    const senderTxRef = db.collection('transactions').doc()
    const receiverTxRef = db.collection('transactions').doc()

    await db.runTransaction(async (t) => {
      const senderSnap = await t.get(senderRef)
      const receiverSnap = await t.get(receiverRef)

      if (!senderSnap.exists) throw new Error('SENDER_NOT_FOUND')
      if (!receiverSnap.exists) throw new Error('RECEIVER_NOT_FOUND')

      const senderBal = Number(senderSnap.data().balance || 0)
      if (senderBal < amt) throw new Error('INSUFFICIENT')

      t.update(senderRef, {
        balance: admin.firestore.FieldValue.increment(-amt),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        'totals.sendMoney': admin.firestore.FieldValue.increment(amt),
        'totals.transactions': admin.firestore.FieldValue.increment(1),
      })

      t.update(receiverRef, {
        balance: admin.firestore.FieldValue.increment(amt),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        'totals.transactions': admin.firestore.FieldValue.increment(1),
      })

      const receiverName = receiverSnap.data().name || ''
      const senderName = senderSnap.data().name || ''
      const senderAccount = senderSnap.data().accountNumber || ''

      t.set(senderTxRef, {
        type: 'send_money',
        amount: amt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: req.uid,
        direction: 'debit',
        counterpartyUserId: receiverUid,
        counterpartyAccount: receiverAcct,
        counterpartyName: receiverName,
        reference: senderTxRef.id,
      })

      t.set(receiverTxRef, {
        type: 'send_money',
        amount: amt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: receiverUid,
        direction: 'credit',
        counterpartyUserId: req.uid,
        counterpartyAccount: senderAccount,
        counterpartyName: senderName,
        reference: senderTxRef.id,
      })
    })

    return res.json({ message: 'Transaction successful', reference: senderTxRef.id })
  } catch (e) {
    const msg = String(e && e.message ? e.message : e)
    if (msg === 'INSUFFICIENT') return res.status(400).json({ error: 'Insufficient funds' })
    if (msg === 'SENDER_NOT_FOUND') return res.status(404).json({ error: 'Sender not found' })
    if (msg === 'RECEIVER_NOT_FOUND') return res.status(404).json({ error: 'Receiver not found' })
    return res.status(500).json({ error: 'Transfer failed' })
  }
})

// --- ADMIN ROUTES (match admin dashboard) ---

app.get('/api/admin/users', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('users').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching users' })
  }
})

app.get('/api/admin/transactions', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('transactions').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching transactions' })
  }
})

app.post('/api/admin/users/:uid/balance', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const targetUid = req.params.uid
  const { amount, type, reason } = req.body || {}
  const amt = Number(amount)
  if (!Number.isFinite(amt) || amt <= 0) return res.status(400).json({ error: 'Invalid amount' })
  const direction = type === 'debit' ? 'debit' : 'credit'
  const delta = direction === 'debit' ? -amt : amt

  try {
    const userRef = db.collection('users').doc(targetUid)
    const txRef = db.collection('transactions').doc()
    await db.runTransaction(async (t) => {
      const snap = await t.get(userRef)
      if (!snap.exists) throw new Error('NOT_FOUND')
      const bal = Number(snap.data().balance || 0)
      if (direction === 'debit' && bal < amt) throw new Error('INSUFFICIENT')

      t.update(userRef, {
        balance: admin.firestore.FieldValue.increment(delta),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        'totals.transactions': admin.firestore.FieldValue.increment(1),
      })
      t.set(txRef, {
        type: direction === 'debit' ? 'admin_debit' : 'admin_credit',
        amount: amt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: targetUid,
        direction,
        remark: reason || '',
        reference: txRef.id,
      })
    })
    return res.json({ message: 'Balance updated', reference: txRef.id })
  } catch (e) {
    const msg = String(e && e.message ? e.message : e)
    if (msg === 'NOT_FOUND') return res.status(404).json({ error: 'User not found' })
    if (msg === 'INSUFFICIENT') return res.status(400).json({ error: 'Insufficient funds' })
    return res.status(500).json({ error: 'Failed to update balance' })
  }
})

app.patch('/api/admin/users/:uid/kyc', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const targetUid = req.params.uid
  const { status } = req.body || {}
  const s = String(status || '').trim()
  if (!s) return res.status(400).json({ error: 'Missing status' })
  try {
    await db.collection('users').doc(targetUid).set({ kycStatus: s, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true })
    res.json({ message: 'KYC status updated' })
  } catch (e) {
    res.status(500).json({ error: 'Error updating KYC status' })
  }
})

app.get('/api/admin/stats', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const [usersCount, txCount] = await Promise.all([
      db.collection('users').count().get(),
      db.collection('transactions').count().get(),
    ])
    res.json({
      totalUsers: usersCount.data().count,
      totalTransactions: txCount.data().count,
      // totals like totalDeposits should be computed from your payment provider/webhooks
      totalDeposits: 0,
    })
  } catch (e) {
    res.status(500).json({ error: 'Error fetching stats' })
  }
})

app.get('/api/banners', async (req, res) => {
  try {
    const q = await db.collection('appBanners').where('active', '==', true).orderBy('priority', 'desc').limit(20).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching banners' })
  }
})

app.get('/api/cards', requireFirebaseAuth, async (req, res) => {
  try {
    const q = await db.collection('cards').where('userId', '==', req.uid).orderBy('createdAt', 'desc').get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching cards' })
  }
})

app.post('/api/cards/order', requireFirebaseAuth, async (req, res) => {
  const { cardType = 'physical', deliveryAddress = '', holderName = '' } = req.body || {}
  const normalizedType = ['virtual', 'physical'].includes(cardType) ? cardType : 'physical'
  try {
    const orderRef = await db.collection('cardOrders').add({
      userId: req.uid,
      cardType: normalizedType,
      deliveryAddress,
      holderName,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    res.status(201).json({ message: 'Card order created', id: orderRef.id })
  } catch (e) {
    res.status(500).json({ error: 'Error creating card order' })
  }
})

app.get('/api/card-orders', requireFirebaseAuth, async (req, res) => {
  try {
    const q = await db.collection('cardOrders').where('userId', '==', req.uid).orderBy('createdAt', 'desc').get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching card orders' })
  }
})

app.get('/api/linked-bank-cards', requireFirebaseAuth, async (req, res) => {
  try {
    const q = await db.collection('linkedBankCards').where('userId', '==', req.uid).orderBy('createdAt', 'desc').get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching linked bank cards' })
  }
})

app.post('/api/linked-bank-cards', requireFirebaseAuth, async (req, res) => {
  const { bankName, holderName, network = 'Visa', last4, expiryMonth = '', expiryYear = '' } = req.body || {}
  if (!bankName || !holderName || !/^\d{4}$/.test(String(last4 || ''))) {
    return res.status(400).json({ error: 'bankName, holderName and last4 are required' })
  }

  try {
    const ref = await db.collection('linkedBankCards').add({
      userId: req.uid,
      bankName,
      holderName,
      network,
      last4: String(last4),
      maskedPan: `**** **** **** ${last4}`,
      expiryMonth,
      expiryYear,
      status: 'active',
      tokenStatus: 'not_tokenized',
      defaultForPayment: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    res.status(201).json({ id: ref.id })
  } catch (e) {
    res.status(500).json({ error: 'Error creating linked bank card' })
  }
})

app.patch('/api/linked-bank-cards/:id', requireFirebaseAuth, async (req, res) => {
  try {
    const ref = db.collection('linkedBankCards').doc(req.params.id)
    const snap = await ref.get()
    if (!snap.exists || snap.data().userId !== req.uid) return res.status(404).json({ error: 'Linked bank card not found' })
    const updates = {}
    for (const key of ['bankName', 'holderName', 'network', 'status', 'defaultForPayment']) {
      if (Object.prototype.hasOwnProperty.call(req.body || {}, key)) updates[key] = req.body[key]
    }
    updates.updatedAt = admin.firestore.FieldValue.serverTimestamp()
    await ref.set(updates, { merge: true })
    res.json({ message: 'Linked bank card updated' })
  } catch (e) {
    res.status(500).json({ error: 'Error updating linked bank card' })
  }
})

app.post('/api/payment-intents/nfc', requireFirebaseAuth, async (req, res) => {
  const { sourceType, cardId, linkedCardId, amount, currency = 'NGN', authMethod = 'biometric_or_pin' } = req.body || {}
  const amt = Number(amount)
  if (!['issued_card', 'linked_bank_card'].includes(sourceType)) return res.status(400).json({ error: 'Invalid sourceType' })
  if (!Number.isFinite(amt) || amt <= 0) return res.status(400).json({ error: 'Invalid amount' })

  try {
    const config = await db.collection('config').doc('cardPayments').get()
    const providerReady = config.data()?.tapToPayProviderEnabled === true
    const ref = await db.collection('paymentIntents').add({
      userId: req.uid,
      sourceType,
      cardId: sourceType === 'issued_card' ? cardId || null : null,
      linkedCardId: sourceType === 'linked_bank_card' ? linkedCardId || null : null,
      amount: amt,
      currency,
      channel: 'nfc_pos',
      authMethod,
      status: providerReady ? 'authorized_waiting_for_tap' : 'provider_required',
      provider: providerReady ? config.data()?.providerName || 'configured_provider' : 'provider_not_configured',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      authorizedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    res.status(201).json({ id: ref.id, providerReady })
  } catch (e) {
    res.status(500).json({ error: 'Error creating NFC payment intent' })
  }
})

app.get('/api/children', requireFirebaseAuth, async (req, res) => {
  try {
    const q = await db.collection('children').where('parentUserId', '==', req.uid).orderBy('createdAt', 'desc').get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching child accounts' })
  }
})

app.post('/api/children', requireFirebaseAuth, async (req, res) => {
  const { name, username, pin, dailyLimit = 0, cardLimit = 0, transferLimit = 0 } = req.body || {}
  if (!name || !username || !pin) return res.status(400).json({ error: 'name, username and pin are required' })
  try {
    const existing = await db.collection('children').where('username', '==', String(username).trim().toLowerCase()).limit(1).get()
    if (!existing.empty) return res.status(409).json({ error: 'Child username already exists' })
    const childRef = await db.collection('children').add({
      parentUserId: req.uid,
      name,
      username: String(username).trim().toLowerCase(),
      pin: String(pin),
      balance: 0,
      dailyLimit: Number(dailyLimit) || 0,
      cardLimit: Number(cardLimit) || 0,
      transferLimit: Number(transferLimit) || 0,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    res.status(201).json({ message: 'Child account created', id: childRef.id })
  } catch (e) {
    res.status(500).json({ error: 'Error creating child account' })
  }
})

app.patch('/api/children/:id/limits', requireFirebaseAuth, async (req, res) => {
  const { dailyLimit, cardLimit, transferLimit } = req.body || {}
  const childRef = db.collection('children').doc(req.params.id)
  try {
    const snap = await childRef.get()
    if (!snap.exists || snap.data().parentUserId !== req.uid) return res.status(404).json({ error: 'Child account not found' })
    await childRef.set({
      dailyLimit: Number(dailyLimit) || 0,
      cardLimit: Number(cardLimit) || 0,
      transferLimit: Number(transferLimit) || 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true })
    res.json({ message: 'Limits updated' })
  } catch (e) {
    res.status(500).json({ error: 'Error updating child limits' })
  }
})

app.post('/api/child-auth/login', async (req, res) => {
  const { username, pin } = req.body || {}
  if (!username || !pin) return res.status(400).json({ error: 'username and pin are required' })
  try {
    const q = await db.collection('children').where('username', '==', String(username).trim().toLowerCase()).limit(1).get()
    if (q.empty || String(q.docs[0].data().pin) !== String(pin)) return res.status(401).json({ error: 'Invalid child credentials' })
    const data = q.docs[0].data()
    if (data.status !== 'active') return res.status(403).json({ error: 'Child account disabled' })
    res.json({ id: q.docs[0].id, ...data, pin: undefined })
  } catch (e) {
    res.status(500).json({ error: 'Child login failed' })
  }
})

app.get('/api/admin/cards', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('cards').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching cards' })
  }
})

app.get('/api/admin/card-orders', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('cardOrders').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching card orders' })
  }
})

app.get('/api/admin/linked-bank-cards', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('linkedBankCards').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching linked bank cards' })
  }
})

app.get('/api/admin/payment-intents', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('paymentIntents').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching payment intents' })
  }
})

app.patch('/api/admin/payment-intents/:id', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { status, providerReference = '' } = req.body || {}
  if (!status) return res.status(400).json({ error: 'status is required' })
  try {
    await db.collection('paymentIntents').doc(req.params.id).set({
      status,
      providerReference,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true })
    res.json({ message: 'Payment intent updated' })
  } catch (e) {
    res.status(500).json({ error: 'Error updating payment intent' })
  }
})

app.patch('/api/admin/card-orders/:id', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { status } = req.body || {}
  try {
    await db.collection('cardOrders').doc(req.params.id).set({
      status: status || 'pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true })
    res.json({ message: 'Card order updated' })
  } catch (e) {
    res.status(500).json({ error: 'Error updating card order' })
  }
})

app.get('/api/admin/children', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('children').orderBy('createdAt', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data(), pin: undefined })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching child accounts' })
  }
})

app.get('/api/admin/banners', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const q = await db.collection('appBanners').orderBy('priority', 'desc').limit(1000).get()
    res.json(q.docs.map((d) => ({ id: d.id, ...d.data() })))
  } catch (e) {
    res.status(500).json({ error: 'Error fetching banners' })
  }
})

app.post('/api/admin/banners', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { title, subtitle = '', imageUrl = '', actionUrl = '', active = true, priority = 0 } = req.body || {}
  if (!title) return res.status(400).json({ error: 'title is required' })
  try {
    const ref = await db.collection('appBanners').add({
      title,
      subtitle,
      imageUrl,
      actionUrl,
      active: !!active,
      priority: Number(priority) || 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    res.status(201).json({ id: ref.id })
  } catch (e) {
    res.status(500).json({ error: 'Error creating banner' })
  }
})

app.patch('/api/admin/banners/:id', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    await db.collection('appBanners').doc(req.params.id).set({
      ...req.body,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true })
    res.json({ message: 'Banner updated' })
  } catch (e) {
    res.status(500).json({ error: 'Error updating banner' })
  }
})

app.post('/api/admin/push-notifications', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { title, body, audience = 'all' } = req.body || {}
  if (!title || !body) return res.status(400).json({ error: 'title and body are required' })
  try {
    const ref = await db.collection('notifications').add({
      title,
      body,
      audience,
      status: 'queued',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    // Delivery is intentionally queued; Cloud Functions can fan out to FCM tokens.
    res.status(201).json({ id: ref.id, status: 'queued' })
  } catch (e) {
    res.status(500).json({ error: 'Error queueing push notification' })
  }
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT} (Firebase mode)`)
})
