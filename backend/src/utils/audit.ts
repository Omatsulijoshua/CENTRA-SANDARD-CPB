import { prisma } from '../config/prisma.js'

export async function audit(action: string, input: {
  actorUserId?: string
  businessId?: string
  targetType?: string
  targetId?: string
  ipAddress?: string
  deviceId?: string
  metadata?: Record<string, unknown>
}) {
  await prisma.auditLog.create({
    data: {
      action,
      actorUserId: input.actorUserId,
      businessId: input.businessId,
      targetType: input.targetType,
      targetId: input.targetId,
      ipAddress: input.ipAddress,
      deviceId: input.deviceId,
      metadata: input.metadata as any,
    },
  })
}
