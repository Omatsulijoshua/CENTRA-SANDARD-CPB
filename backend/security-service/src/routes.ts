import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth } from '../../src/middleware/auth.js'
import { audit } from '../../src/utils/audit.js'

export const securityRouter = Router()

securityRouter.use(requireAuth)

securityRouter.post('/devices/register', async (req, res, next) => {
  try {
    const body = z.object({
      fingerprint: z.string(),
      platform: z.string(),
      model: z.string().optional(),
      rooted: z.boolean().default(false),
      emulator: z.boolean().default(false),
    }).parse(req.body)
    const device = await prisma.device.upsert({
      where: { fingerprint: body.fingerprint },
      create: { userId: req.auth!.id, ...body, trusted: !body.rooted && !body.emulator, lastSeenAt: new Date() },
      update: { ...body, trusted: !body.rooted && !body.emulator, lastSeenAt: new Date() },
    })
    await audit('device_registered', { actorUserId: req.auth!.id, businessId: req.auth!.businessId, targetType: 'device', targetId: device.id, metadata: body })
    res.status(201).json(device)
  } catch (error) {
    next(error)
  }
})

securityRouter.get('/audit-logs', async (req, res) => {
  const logs = await prisma.auditLog.findMany({
    where: { businessId: req.auth!.businessId },
    orderBy: { createdAt: 'desc' },
    take: 200,
  })
  res.json(logs)
})
