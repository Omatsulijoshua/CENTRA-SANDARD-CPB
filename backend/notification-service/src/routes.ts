import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth, requireRole } from '../../src/middleware/auth.js'

export const notificationRouter = Router()

notificationRouter.use(requireAuth)

notificationRouter.get('/', async (req, res) => {
  const notifications = await prisma.notification.findMany({
    where: { OR: [{ userId: req.auth!.id }, { businessId: req.auth!.businessId }] },
    orderBy: { createdAt: 'desc' },
    take: 100,
  })
  res.json(notifications)
})

notificationRouter.post('/send', requireRole('OWNER', 'ADMIN'), async (req, res, next) => {
  try {
    const body = z.object({ userId: z.string().optional(), title: z.string(), body: z.string(), channel: z.enum(['PUSH', 'EMAIL', 'SMS', 'VOICE']).default('PUSH') }).parse(req.body)
    const notification = await prisma.notification.create({ data: { ...body, businessId: req.auth!.businessId } })
    res.status(201).json(notification)
  } catch (error) {
    next(error)
  }
})
