import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth, requireRole } from '../../src/middleware/auth.js'
import { audit } from '../../src/utils/audit.js'

export const kycRouter = Router()

kycRouter.use(requireAuth)

kycRouter.post('/documents', requireRole('OWNER'), async (req, res, next) => {
  try {
    const body = z.object({
      type: z.enum(['CAC', 'BVN', 'NIN', 'SELFIE', 'UTILITY_BILL', 'TAX_ID']),
      fileUrl: z.string().url(),
    }).parse(req.body)
    const document = await prisma.kycDocument.create({ data: { businessId: req.auth!.businessId!, ...body } })
    await audit('kyc_document_uploaded', { actorUserId: req.auth!.id, businessId: req.auth!.businessId, targetType: 'kyc_document', targetId: document.id })
    res.status(201).json(document)
  } catch (error) {
    next(error)
  }
})

kycRouter.get('/documents', requireRole('OWNER', 'ADMIN'), async (req, res) => {
  const documents = await prisma.kycDocument.findMany({ where: { businessId: req.auth!.businessId }, orderBy: { createdAt: 'desc' } })
  res.json(documents)
})
