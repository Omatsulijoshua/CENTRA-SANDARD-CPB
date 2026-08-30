import { Router, Request, Response, NextFunction } from 'express'
import { PrismaClient, UserRole } from '@prisma/client'
import admin from 'firebase-admin'
import { z } from 'zod'

const prisma = new PrismaClient()

export const personalRouter = Router()

// Initialize Firebase Admin SDK if not already initialized
let firebaseInitialized = false
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
    firebaseInitialized = true
    console.log('Firebase initialized inside Personal Router')
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_FILE) {
    const fs = await import('fs')
    const serviceAccount = JSON.parse(fs.readFileSync(process.env.FIREBASE_SERVICE_ACCOUNT_FILE, 'utf8'))
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
    firebaseInitialized = true
    console.log('Firebase initialized inside Personal Router')
  }
} catch (e: any) {
  console.warn('Firebase Admin initialization skipped or failed:', e.message)
}

// Extend Request interface locally
interface AuthenticatedRequest extends Request {
  user?: any
  uid?: string
}

// Utility to generate a unique 10-digit account number
function generateAccountNumber(): string {
  const first = Math.floor(Math.random() * 9) + 1
  const rest = Array.from({ length: 9 }, () => Math.floor(Math.random() * 10)).join('')
  return `${first}${rest}`
}

// Authentication Middleware using Firebase
const requireFirebaseAuth = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization || ''
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null

  if (!token) {
    return res.status(401).json({ error: 'Missing Authorization Bearer token' })
  }

  try {
    let decoded: admin.auth.DecodedIdToken
    
    if (firebaseInitialized) {
      decoded = await admin.auth().verifyIdToken(token)
    } else {
      // Mock validation in development if Firebase is not initialized
      if (process.env.NODE_ENV !== 'production' && token.startsWith('mock-')) {
        const mockUid = token.replace('mock-', '')
        decoded = {
          uid: mockUid,
          email: `${mockUid}@example.com`,
          name: `Mock User ${mockUid}`,
          aud: '',
          exp: 0,
          iat: 0,
          iss: '',
          sub: '',
          auth_time: 0,
          firebase: { identities: {}, sign_in_provider: 'custom' },
        } as any
      } else {
        return res.status(503).json({ error: 'Firebase authentication service unavailable' })
      }
    }

    req.uid = decoded.uid

    // Check if user exists in Postgres database, otherwise create them
    let user = await prisma.user.findUnique({
      where: { firebaseUid: decoded.uid },
    })

    if (!user) {
      let accountNumber = generateAccountNumber()
      // Ensure account number uniqueness
      let attempts = 0
      while (attempts < 5) {
        const existing = await prisma.user.findUnique({ where: { accountNumber } })
        if (!existing) break
        accountNumber = generateAccountNumber()
        attempts++
      }

      user = await prisma.user.create({
        data: {
          firebaseUid: decoded.uid,
          email: decoded.email || `${decoded.uid}@centra.com`,
          fullName: decoded.name || 'Centra User',
          role: UserRole.USER,
          accountNumber,
          balance: 10000.0, // initial welcome balance
          kycStatus: 'PENDING',
        },
      })
    }

    req.user = user
    next()
  } catch (e: any) {
    return res.status(401).json({ error: 'Invalid token: ' + e.message })
  }
}

const requireAdmin = (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  if (!req.user || req.user.role !== UserRole.ADMIN) {
    return res.status(403).json({ error: 'Access denied. Admin only.' })
  }
  next()
}

// Health Check
personalRouter.get('/health', (_req, res) => {
  res.json({ ok: true, mode: firebaseInitialized ? 'firebase' : 'mock' })
})

// --- USER ROUTES ---

personalRouter.get('/user/profile', requireFirebaseAuth, (req: AuthenticatedRequest, res) => {
  res.json(req.user)
})

personalRouter.get('/transactions', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  try {
    const txs = await prisma.transaction.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 100,
    })
    res.json(txs)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching transactions: ' + e.message })
  }
})

personalRouter.post('/banks/resolve', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { accountNumber } = req.body || {}
  if (!accountNumber || String(accountNumber).length !== 10) {
    return res.status(400).json({ error: 'Invalid account number' })
  }

  try {
    const targetUser = await prisma.user.findUnique({
      where: { accountNumber: String(accountNumber) },
    })

    if (targetUser) {
      return res.json({ accountName: targetUser.fullName, internal: true })
    }

    // Mock external bank resolution
    const mockNames = ['Chinedu Okafor', 'Fatima Bello', 'Oluwaseun Adeyemi', 'Ngozi Eze']
    const idx = Number(String(accountNumber).slice(0, 1)) % mockNames.length
    return res.json({ accountName: mockNames[idx], internal: false })
  } catch (e: any) {
    return res.status(500).json({ error: 'Resolve failed: ' + e.message })
  }
})

personalRouter.post('/transactions/send', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { receiverAccountNumber, amount } = req.body || {}
  const amt = Number(amount)
  const receiverAcct = String(receiverAccountNumber || '').trim()

  if (!receiverAcct || receiverAcct.length !== 10) {
    return res.status(400).json({ error: 'Invalid receiver account number' })
  }
  if (!Number.isFinite(amt) || amt <= 0) {
    return res.status(400).json({ error: 'Invalid amount' })
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      const sender = await tx.user.findUnique({
        where: { id: req.user.id },
      })
      if (!sender) throw new Error('SENDER_NOT_FOUND')
      if (Number(sender.balance) < amt) throw new Error('INSUFFICIENT')

      const receiver = await tx.user.findUnique({
        where: { accountNumber: receiverAcct },
      })
      if (!receiver) throw new Error('RECEIVER_NOT_FOUND')
      if (receiver.id === sender.id) throw new Error('SELF_TRANSFER')

      // Perform updates
      await tx.user.update({
        where: { id: sender.id },
        data: { balance: { decrement: amt } },
      })

      await tx.user.update({
        where: { id: receiver.id },
        data: { balance: { increment: amt } },
      })

      // Write Transaction records
      const senderTx = await tx.transaction.create({
        data: {
          userId: sender.id,
          amount: amt,
          type: 'WALLET_TRANSFER',
          channel: 'WALLET',
          direction: 'debit',
          status: 'SUCCEEDED',
          provider: 'CENTRA',
          providerRef: `TX-SND-${Date.now()}`,
          metadata: {
            counterpartyUserId: receiver.id,
            counterpartyAccount: receiverAcct,
            counterpartyName: receiver.fullName,
          },
        },
      })

      const receiverTx = await tx.transaction.create({
        data: {
          userId: receiver.id,
          amount: amt,
          type: 'WALLET_TRANSFER',
          channel: 'WALLET',
          direction: 'credit',
          status: 'SUCCEEDED',
          provider: 'CENTRA',
          providerRef: senderTx.id,
          metadata: {
            counterpartyUserId: sender.id,
            counterpartyAccount: sender.accountNumber,
            counterpartyName: sender.fullName,
          },
        },
      })

      return { senderTx }
    })

    return res.json({ message: 'Transaction successful', reference: result.senderTx.id })
  } catch (e: any) {
    const msg = e.message
    if (msg === 'INSUFFICIENT') return res.status(400).json({ error: 'Insufficient funds' })
    if (msg === 'SENDER_NOT_FOUND') return res.status(404).json({ error: 'Sender not found' })
    if (msg === 'RECEIVER_NOT_FOUND') return res.status(404).json({ error: 'Receiver not found' })
    if (msg === 'SELF_TRANSFER') return res.status(400).json({ error: 'Cannot send money to yourself' })
    return res.status(500).json({ error: 'Transfer failed: ' + e.message })
  }
})

// --- CARDS ---

personalRouter.get('/cards', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  try {
    const cards = await prisma.card.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    })
    res.json(cards)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching cards: ' + e.message })
  }
})

personalRouter.post('/cards/order', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { cardType = 'physical', deliveryAddress = '', holderName = '' } = req.body || {}
  try {
    const order = await prisma.cardOrder.create({
      data: {
        userId: req.user.id,
        cardType,
        deliveryAddress,
        holderName: holderName || req.user.fullName,
        status: 'pending',
      },
    })
    res.status(201).json({ message: 'Card order created', id: order.id })
  } catch (e: any) {
    res.status(500).json({ error: 'Error creating card order: ' + e.message })
  }
})

personalRouter.get('/card-orders', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  try {
    const orders = await prisma.cardOrder.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    })
    res.json(orders)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching card orders: ' + e.message })
  }
})

personalRouter.get('/linked-bank-cards', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  try {
    const cards = await prisma.linkedBankCard.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
    })
    res.json(cards)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching linked bank cards: ' + e.message })
  }
})

personalRouter.post('/linked-bank-cards', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { bankName, holderName, network = 'Visa', last4, expiryMonth = '', expiryYear = '' } = req.body || {}
  if (!bankName || !holderName || !/^\d{4}$/.test(String(last4 || ''))) {
    return res.status(400).json({ error: 'bankName, holderName and last4 are required' })
  }

  try {
    const card = await prisma.linkedBankCard.create({
      data: {
        userId: req.user.id,
        bankName,
        holderName,
        network,
        last4: String(last4),
        maskedPan: `**** **** **** ${last4}`,
        expiryMonth,
        expiryYear,
        status: 'active',
      },
    })
    res.status(201).json({ id: card.id })
  } catch (e: any) {
    res.status(500).json({ error: 'Error linking bank card: ' + e.message })
  }
})

personalRouter.patch('/linked-bank-cards/:id', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  try {
    const card = await prisma.linkedBankCard.findFirst({
      where: { id: req.params.id as string, userId: req.user.id },
    })
    if (!card) return res.status(404).json({ error: 'Linked card not found' })

    const updates: any = {}
    for (const key of ['bankName', 'holderName', 'network', 'status', 'defaultForPayment']) {
      if (req.body[key] !== undefined) updates[key] = req.body[key]
    }

    const updated = await prisma.linkedBankCard.update({
      where: { id: req.params.id as string },
      data: updates,
    })

    res.json({ message: 'Linked bank card updated', card: updated })
  } catch (e: any) {
    res.status(500).json({ error: 'Error updating card: ' + e.message })
  }
})

personalRouter.post('/payment-intents/nfc', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { sourceType, cardId, linkedCardId, amount, currency = 'NGN', authMethod = 'biometric_or_pin' } = req.body || {}
  const amt = Number(amount)
  if (!['issued_card', 'linked_bank_card'].includes(sourceType)) {
    return res.status(400).json({ error: 'Invalid sourceType' })
  }
  if (!Number.isFinite(amt) || amt <= 0) {
    return res.status(400).json({ error: 'Invalid amount' })
  }

  try {
    const intent = await prisma.paymentIntent.create({
      data: {
        userId: req.user.id,
        sourceType,
        cardId: sourceType === 'issued_card' ? cardId : null,
        linkedCardId: sourceType === 'linked_bank_card' ? linkedCardId : null,
        amount: amt,
        currency,
        channel: 'nfc_pos',
        authMethod,
        status: 'authorized_waiting_for_tap',
        provider: 'configured_provider',
      },
    })
    res.status(201).json({ id: intent.id, providerReady: true })
  } catch (e: any) {
    res.status(500).json({ error: 'Error creating NFC payment intent: ' + e.message })
  }
})

// --- CHILDREN ACCOUNTS ---

personalRouter.get('/children', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  try {
    const children = await prisma.childAccount.findMany({
      where: { parentUserId: req.user.id },
      orderBy: { createdAt: 'desc' },
    })
    res.json(children)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching children: ' + e.message })
  }
})

personalRouter.post('/children', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { name, username, pin, dailyLimit = 0, cardLimit = 0, transferLimit = 0 } = req.body || {}
  if (!name || !username || !pin) {
    return res.status(400).json({ error: 'name, username and pin are required' })
  }

  try {
    const existing = await prisma.childAccount.findUnique({
      where: { username: String(username).trim().toLowerCase() },
    })
    if (existing) return res.status(409).json({ error: 'Child username already exists' })

    const child = await prisma.childAccount.create({
      data: {
        parentUserId: req.user.id,
        name,
        username: String(username).trim().toLowerCase(),
        pin: String(pin),
        balance: 0,
        dailyLimit: Number(dailyLimit) || 0,
        cardLimit: Number(cardLimit) || 0,
        transferLimit: Number(transferLimit) || 0,
        status: 'active',
      },
    })
    res.status(201).json({ message: 'Child account created', id: child.id })
  } catch (e: any) {
    res.status(500).json({ error: 'Error creating child account: ' + e.message })
  }
})

personalRouter.patch('/children/:id/limits', requireFirebaseAuth, async (req: AuthenticatedRequest, res) => {
  const { dailyLimit, cardLimit, transferLimit } = req.body || {}
  try {
    const child = await prisma.childAccount.findFirst({
      where: { id: req.params.id as string, parentUserId: req.user.id },
    })
    if (!child) return res.status(404).json({ error: 'Child account not found' })

    const updated = await prisma.childAccount.update({
      where: { id: req.params.id as string },
      data: {
        dailyLimit: Number(dailyLimit) || 0,
        cardLimit: Number(cardLimit) || 0,
        transferLimit: Number(transferLimit) || 0,
      },
    })

    res.json({ message: 'Limits updated', child: updated })
  } catch (e: any) {
    res.status(500).json({ error: 'Error updating child limits: ' + e.message })
  }
})

personalRouter.post('/child-auth/login', async (req, res) => {
  const { username, pin } = req.body || {}
  if (!username || !pin) {
    return res.status(400).json({ error: 'username and pin are required' })
  }

  try {
    const child = await prisma.childAccount.findUnique({
      where: { username: String(username).trim().toLowerCase() },
    })
    if (!child || String(child.pin) !== String(pin)) {
      return res.status(401).json({ error: 'Invalid child credentials' })
    }
    if (child.status !== 'active') {
      return res.status(403).json({ error: 'Child account disabled' })
    }
    res.json({ ...child, pin: undefined })
  } catch (e: any) {
    res.status(500).json({ error: 'Child login failed: ' + e.message })
  }
})

personalRouter.get('/banners', async (_req, res) => {
  try {
    const banners = await prisma.appBanner.findMany({
      where: { active: true },
      orderBy: { priority: 'desc' },
      take: 20,
    })
    res.json(banners)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching banners: ' + e.message })
  }
})

// --- ADMIN ROUTES ---

personalRouter.get('/admin/users', requireFirebaseAuth, requireAdmin, async (_req, res) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      take: 1000,
    })
    res.json(users)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching users: ' + e.message })
  }
})

personalRouter.get('/admin/transactions', requireFirebaseAuth, requireAdmin, async (_req, res) => {
  try {
    const txs = await prisma.transaction.findMany({
      orderBy: { createdAt: 'desc' },
      take: 1000,
    })
    res.json(txs)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching transactions: ' + e.message })
  }
})

personalRouter.post('/admin/users/:uid/balance', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const targetUid = req.params.uid as string
  const { amount, type, reason } = req.body || {}
  const amt = Number(amount)
  if (!Number.isFinite(amt) || amt <= 0) return res.status(400).json({ error: 'Invalid amount' })
  const direction = type === 'debit' ? 'debit' : 'credit'
  const delta = direction === 'debit' ? -amt : amt

  try {
    const result = await prisma.$transaction(async (tx) => {
      const target = await tx.user.findUnique({ where: { id: targetUid } })
      if (!target) throw new Error('NOT_FOUND')
      
      if (direction === 'debit' && Number(target.balance) < amt) {
        throw new Error('INSUFFICIENT')
      }

      await tx.user.update({
        where: { id: targetUid },
        data: { balance: { increment: delta } },
      })

      const newTx = await tx.transaction.create({
        data: {
          userId: targetUid,
          amount: amt,
          type: 'WALLET_TRANSFER', // Fallback enum
          channel: 'WALLET',
          direction,
          status: 'SUCCEEDED',
          provider: 'ADMIN',
          providerRef: `TX-ADM-${Date.now()}`,
          metadata: { remark: reason || '' },
        },
      })
      return newTx
    })

    return res.json({ message: 'Balance updated', reference: result.id })
  } catch (e: any) {
    if (e.message === 'NOT_FOUND') return res.status(404).json({ error: 'User not found' })
    if (e.message === 'INSUFFICIENT') return res.status(400).json({ error: 'Insufficient funds' })
    return res.status(500).json({ error: 'Failed to update balance: ' + e.message })
  }
})

personalRouter.patch('/admin/users/:uid/kyc', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const targetUid = req.params.uid as string
  const { status } = req.body || {}
  if (!status) return res.status(400).json({ error: 'Missing status' })
  try {
    const updated = await prisma.user.update({
      where: { id: targetUid },
      data: { kycStatus: status },
    })
    res.json({ message: 'KYC status updated', user: updated })
  } catch (e: any) {
    res.status(500).json({ error: 'Error updating KYC status: ' + e.message })
  }
})

personalRouter.get('/admin/stats', requireFirebaseAuth, requireAdmin, async (_req, res) => {
  try {
    const totalUsers = await prisma.user.count()
    const totalTransactions = await prisma.transaction.count()
    const usersWithBalances = await prisma.user.findMany({
      select: { balance: true },
    })
    const totalDeposits = usersWithBalances.reduce((sum, user) => sum + Number(user.balance), 0)

    res.json({
      totalUsers,
      totalTransactions,
      totalDeposits,
    })
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching stats: ' + e.message })
  }
})

// Banners Admin
personalRouter.post('/admin/banners', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { title, subtitle = '', imageUrl = '', actionUrl = '', active = true, priority = 0 } = req.body || {}
  if (!title) return res.status(400).json({ error: 'title is required' })
  try {
    const banner = await prisma.appBanner.create({
      data: {
        title,
        subtitle,
        imageUrl,
        actionUrl,
        active: !!active,
        priority: Number(priority) || 0,
      },
    })
    res.status(201).json({ id: banner.id })
  } catch (e: any) {
    res.status(500).json({ error: 'Error creating banner: ' + e.message })
  }
})

personalRouter.patch('/admin/banners/:id', requireFirebaseAuth, requireAdmin, async (req, res) => {
  try {
    const updated = await prisma.appBanner.update({
      where: { id: req.params.id as string },
      data: req.body,
    })
    res.json({ message: 'Banner updated', banner: updated })
  } catch (e: any) {
    res.status(500).json({ error: 'Error updating banner: ' + e.message })
  }
})

// --- BUSINESS ADMIN ENDPOINTS ---

personalRouter.get('/admin/businesses', requireFirebaseAuth, requireAdmin, async (_req, res) => {
  try {
    const businesses = await prisma.business.findMany({
      include: { owner: true },
      orderBy: { createdAt: 'desc' },
    })
    res.json(businesses)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching businesses: ' + e.message })
  }
})

personalRouter.patch('/admin/businesses/:id/kyc', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { status } = req.body
  try {
    const updated = await prisma.business.update({
      where: { id: req.params.id as string },
      data: { kycStatus: status },
    })
    res.json(updated)
  } catch (e: any) {
    res.status(500).json({ error: 'Error updating business KYC: ' + e.message })
  }
})

personalRouter.get('/admin/fraud-flags', requireFirebaseAuth, requireAdmin, async (_req, res) => {
  try {
    const flags = await prisma.fraudFlag.findMany({
      orderBy: { createdAt: 'desc' },
    })
    res.json(flags)
  } catch (e: any) {
    res.status(500).json({ error: 'Error fetching fraud flags: ' + e.message })
  }
})

personalRouter.patch('/admin/fraud-flags/:id/resolve', requireFirebaseAuth, requireAdmin, async (req, res) => {
  const { resolved } = req.body
  try {
    const updated = await prisma.fraudFlag.update({
      where: { id: req.params.id as string },
      data: { resolved: !!resolved },
    })
    res.json(updated)
  } catch (e: any) {
    res.status(500).json({ error: 'Error resolving fraud flag: ' + e.message })
  }
})
