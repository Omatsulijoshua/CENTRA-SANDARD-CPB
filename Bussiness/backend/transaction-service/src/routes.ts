import { Router } from 'express'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth } from '../../src/middleware/auth.js'

export const transactionRouter = Router()

transactionRouter.use(requireAuth)

transactionRouter.get('/', async (req, res) => {
  const where = req.auth!.role === 'EMPLOYEE'
    ? { employeeId: req.auth!.employeeId }
    : { businessId: req.auth!.businessId }
  const transactions = await prisma.transaction.findMany({ where, orderBy: { createdAt: 'desc' }, take: 200 })
  res.json(transactions)
})
