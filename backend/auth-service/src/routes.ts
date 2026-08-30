import { Router } from 'express'
import bcrypt from 'bcryptjs'
import { z } from 'zod'
import type { Prisma } from '@prisma/client'
import { prisma } from '../../src/config/prisma.js'
import { signAccessToken } from '../../src/middleware/auth.js'
import { requireDeviceFingerprint } from '../../src/middleware/security.js'
import { audit } from '../../src/utils/audit.js'

export const authRouter = Router()

const ownerSignupSchema = z.object({
  fullName: z.string().min(2),
  email: z.string().email(),
  phone: z.string().min(8),
  password: z.string().min(8),
  businessName: z.string().min(2),
  category: z.string().min(2),
  address: z.string().min(2),
  cacNumber: z.string().optional(),
  taxId: z.string().optional(),
  useExistingCpbProfile: z.boolean().default(false),
})

authRouter.post('/signup-business', requireDeviceFingerprint, async (req, res, next) => {
  try {
    const body = ownerSignupSchema.parse(req.body)
    const passwordHash = await bcrypt.hash(body.password, 12)
    const result = await prisma.$transaction(async (tx: Prisma.TransactionClient) => {
      const owner = await tx.user.create({
        data: {
          fullName: body.fullName,
          email: body.email,
          phone: body.phone,
          role: 'OWNER',
          passwordHash,
        },
      })
      const business = await tx.business.create({
        data: {
          ownerId: owner.id,
          name: body.businessName,
          cacNumber: body.cacNumber,
          taxId: body.taxId,
          category: body.category,
          address: body.address,
          wallets: { create: { currency: 'NGN' } },
          limits: {
            createMany: {
              data: [
                { scope: 'BUSINESS', period: 'PER_TRANSACTION', amount: 100000 },
                { scope: 'BUSINESS', period: 'DAILY', amount: 500000 },
              ],
            },
          },
        },
      })
      return { owner, business }
    })
    await audit('business_owner_signup', { actorUserId: result.owner.id, businessId: result.business.id, ipAddress: req.ip })
    res.status(201).json({
      accessToken: signAccessToken({ id: result.owner.id, role: 'OWNER', businessId: result.business.id }),
      owner: result.owner,
      business: result.business,
    })
  } catch (error) {
    next(error)
  }
})

authRouter.post('/login-owner', requireDeviceFingerprint, async (req, res, next) => {
  try {
    const { email, password } = z.object({ email: z.string().email(), password: z.string() }).parse(req.body)
    const user = await prisma.user.findUnique({ where: { email }, include: { ownedBusinesses: true } })
    if (!user || user.role !== 'OWNER' || !user.passwordHash || !(await bcrypt.compare(password, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid owner credentials' })
    }
    const businessId = user.ownedBusinesses[0]?.id
    await audit('owner_login', { actorUserId: user.id, businessId, ipAddress: req.ip })
    res.json({ accessToken: signAccessToken({ id: user.id, role: 'OWNER', businessId }), user, businessId })
  } catch (error) {
    next(error)
  }
})

authRouter.post('/login-employee', requireDeviceFingerprint, async (req, res, next) => {
  try {
    const { phone, pin } = z.object({ phone: z.string(), pin: z.string().min(4) }).parse(req.body)
    const user = await prisma.user.findUnique({ where: { phone }, include: { employeeProfile: true } })
    if (!user || user.role !== 'EMPLOYEE' || !user.passwordHash || !(await bcrypt.compare(pin, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid employee credentials' })
    }
    if (!user.employeeProfile || user.employeeProfile.status !== 'ACTIVE') {
      return res.status(403).json({ error: 'Employee profile is not active' })
    }
    await audit('employee_login', { actorUserId: user.id, businessId: user.employeeProfile.businessId, targetId: user.employeeProfile.id, ipAddress: req.ip })
    res.json({
      accessToken: signAccessToken({ id: user.id, role: 'EMPLOYEE', businessId: user.employeeProfile.businessId, employeeId: user.employeeProfile.id }),
      user,
      employee: user.employeeProfile,
    })
  } catch (error) {
    next(error)
  }
})
