import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth, requireRole } from '../../src/middleware/auth.js'
import { audit } from '../../src/utils/audit.js'

export const walletRouter = Router()

walletRouter.use(requireAuth)

walletRouter.get('/', requireRole('OWNER'), async (req, res) => {
  const wallets = await prisma.wallet.findMany({ where: { businessId: req.auth!.businessId } })
  res.json(wallets)
})

walletRouter.post('/withdraw', requireRole('OWNER'), async (req, res, next) => {
  try {
    const body = z.object({ amount: z.coerce.number().positive(), settlementAccount: z.string().min(10) }).parse(req.body)
    await audit('wallet_withdrawal_requested', { actorUserId: req.auth!.id, businessId: req.auth!.businessId, metadata: body })
    res.status(202).json({ status: 'pending_approval', message: 'Withdrawal requires owner approval and provider settlement.' })
  } catch (error) {
    next(error)
  }
})
