import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../../src/config/prisma.js'
import { env } from '../../src/config/env.js'
import { requireAuth, requireRole } from '../../src/middleware/auth.js'
import { audit } from '../../src/utils/audit.js'
import { isBlockedByLimits, scoreFraud } from '../../src/utils/fraud.js'

export const nfcRouter = Router()

nfcRouter.use(requireAuth)

nfcRouter.post('/initiate', requireRole('OWNER', 'EMPLOYEE'), async (req, res, next) => {
  try {
    const body = z.object({
      amount: z.coerce.number().positive().max(env.MAX_TRANSACTION_AMOUNT),
      currency: z.string().default('NGN'),
      receiverDeviceId: z.string().optional(),
      customerInstrument: z.enum(['CONTACTLESS_CARD', 'APPLE_PAY', 'GOOGLE_PAY', 'NFC_PHONE', 'ATM_CARD']).default('CONTACTLESS_CARD'),
    }).parse(req.body)
    const businessId = req.auth!.businessId!
    const employeeId = req.auth!.role === 'EMPLOYEE' ? req.auth!.employeeId : undefined
    const startOfDay = new Date()
    startOfDay.setHours(0, 0, 0, 0)
    const today = await prisma.transaction.aggregate({
      _sum: { amount: true },
      where: { businessId, employeeId, createdAt: { gte: startOfDay }, status: { in: ['SUCCEEDED', 'AUTHORIZED'] } },
    })
    const dailyTotal = Number(today._sum.amount || 0)
    const riskScore = scoreFraud({ amount: body.amount, dailyTotal })
    if (isBlockedByLimits(body.amount, dailyTotal)) {
      return res.status(422).json({ error: 'Transaction exceeds safety limits', maxTransaction: env.MAX_TRANSACTION_AMOUNT, maxDaily: env.MAX_DAILY_EMPLOYEE_AMOUNT })
    }
    const transaction = await prisma.transaction.create({
      data: {
        businessId,
        employeeId,
        type: 'NFC_TAP',
        channel: 'NFC',
        amount: body.amount,
        currency: body.currency,
        status: env.NFC_PROVIDER_ENABLED ? 'INITIATED' : 'PENDING_PROVIDER',
        provider: env.PAYMENT_PROVIDER,
        riskScore,
        metadata: {
          customerInstrument: body.customerInstrument,
          pinEntryRule: 'PIN must be entered on customer device or PCI-compliant provider secure input only',
        },
        nfcSession: {
          create: {
            businessId,
            employeeId,
            receiverDeviceId: body.receiverDeviceId,
            status: env.NFC_PROVIDER_ENABLED ? 'WAITING_FOR_TAP' : 'PROVIDER_REQUIRED',
            expiresAt: new Date(Date.now() + 5 * 60_000),
          },
        },
      },
      include: { nfcSession: true },
    })
    await audit('nfc_receive_initiated', { actorUserId: req.auth!.id, businessId, targetType: 'transaction', targetId: transaction.id, metadata: { amount: body.amount } })
    res.status(201).json({ transaction, providerRequired: !env.NFC_PROVIDER_ENABLED })
  } catch (error) {
    next(error)
  }
})

nfcRouter.post('/confirm', requireRole('OWNER', 'EMPLOYEE'), async (req, res, next) => {
  try {
    const body = z.object({ transactionId: z.string(), providerRef: z.string(), status: z.enum(['SUCCEEDED', 'FAILED', 'CANCELLED']) }).parse(req.body)
    const transaction = await prisma.transaction.update({
      where: { id: body.transactionId },
      data: { status: body.status, providerRef: body.providerRef, nfcSession: { update: { status: body.status === 'SUCCEEDED' ? 'SUCCEEDED' : 'FAILED' } } },
      include: { nfcSession: true },
    })
    await audit('nfc_receive_confirmed', { actorUserId: req.auth!.id, businessId: transaction.businessId ?? undefined, targetType: 'transaction', targetId: transaction.id, metadata: { status: body.status } })
    res.json(transaction)
  } catch (error) {
    next(error)
  }
})
