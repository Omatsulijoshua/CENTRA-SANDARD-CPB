import { Router } from 'express'
import bcrypt from 'bcryptjs'
import { z } from 'zod'
import type { Prisma } from '@prisma/client'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth, requireRole } from '../../src/middleware/auth.js'
import { audit } from '../../src/utils/audit.js'

export const employeeRouter = Router()

employeeRouter.use(requireAuth)

employeeRouter.post('/create', requireRole('OWNER'), async (req, res, next) => {
  try {
    const body = z.object({
      fullName: z.string().min(2),
      phone: z.string().min(8),
      pin: z.string().min(4),
      branchId: z.string().optional(),
      transactionLimit: z.coerce.number().max(100000).default(100000),
      dailyLimitAmount: z.coerce.number().max(500000).default(500000),
    }).parse(req.body)
    const business = await prisma.business.findUniqueOrThrow({ where: { id: req.auth!.businessId! } })
    const passwordHash = await bcrypt.hash(body.pin, 12)
    const receivingAccount = `${business.name} - ${body.fullName}`
    const employee = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const user = await tx.user.create({ data: { fullName: body.fullName, phone: body.phone, role: 'EMPLOYEE', passwordHash } })
      return tx.employee.create({
        data: {
          userId: user.id,
          businessId: business.id,
          branchId: body.branchId,
          displayName: body.fullName,
          receivingAccount,
          nfcReceiverId: `NFC-${business.id.slice(0, 8)}-${Date.now()}`,
          qrPayload: JSON.stringify({ type: 'centra_business_receive', businessId: business.id, employeeName: body.fullName }),
          transactionLimit: body.transactionLimit,
          dailyLimitAmount: body.dailyLimitAmount,
          permissions: {
            createMany: {
              data: [
                { permission: 'RECEIVE_PAYMENT' },
                { permission: 'VIEW_OWN_TRANSACTIONS' },
                { permission: 'NFC_RECEIVE' },
                { permission: 'QR_RECEIVE' },
                { permission: 'VERIFY_PAYMENT' },
              ],
            },
          },
        },
      })
    })
    await audit('employee_created', { actorUserId: req.auth!.id, businessId: business.id, targetType: 'employee', targetId: employee.id })
    res.status(201).json(employee)
  } catch (error) {
    next(error)
  }
})

employeeRouter.get('/', requireRole('OWNER'), async (req, res) => {
  const employees = await prisma.employee.findMany({
    where: { businessId: req.auth!.businessId! },
    include: { user: true, permissions: true, branch: true },
    orderBy: { createdAt: 'desc' },
  })
  res.json(employees)
})

employeeRouter.patch('/:id/status', requireRole('OWNER'), async (req, res, next) => {
  try {
    const { status, nfcEnabled } = z.object({ status: z.enum(['ACTIVE', 'SUSPENDED', 'FROZEN', 'REMOVED']).optional(), nfcEnabled: z.boolean().optional() }).parse(req.body)
    const employee = await prisma.employee.update({
      where: { id: req.params.id as string },
      data: { status, nfcEnabled },
    })
    await audit('employee_status_changed', { actorUserId: req.auth!.id, businessId: req.auth!.businessId, targetType: 'employee', targetId: employee.id, metadata: { status, nfcEnabled } })
    res.json(employee)
  } catch (error) {
    next(error)
  }
})

employeeRouter.get('/me/transactions', requireRole('EMPLOYEE'), async (req, res) => {
  const transactions = await prisma.transaction.findMany({
    where: { employeeId: req.auth!.employeeId },
    orderBy: { createdAt: 'desc' },
    take: 100,
  })
  res.json(transactions)
})
