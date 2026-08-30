import { Router } from 'express'
import { z } from 'zod'
import { prisma } from '../../src/config/prisma.js'
import { requireAuth, requireRole } from '../../src/middleware/auth.js'
import { audit } from '../../src/utils/audit.js'

export const businessRouter = Router()

businessRouter.use(requireAuth)

businessRouter.get('/me', requireRole('OWNER'), async (req, res) => {
  const business = await prisma.business.findFirst({
    where: { ownerId: req.auth!.id },
    include: { wallets: true, branches: true, employees: true },
  })
  res.json(business)
})

businessRouter.post('/branches', requireRole('OWNER'), async (req, res, next) => {
  try {
    const body = z.object({ name: z.string().min(2), address: z.string().optional() }).parse(req.body)
    const branch = await prisma.branch.create({ data: { businessId: req.auth!.businessId!, ...body } })
    await audit('branch_created', { actorUserId: req.auth!.id, businessId: req.auth!.businessId, targetId: branch.id, targetType: 'branch' })
    res.status(201).json(branch)
  } catch (error) {
    next(error)
  }
})

businessRouter.get('/dashboard', requireRole('OWNER'), async (req, res) => {
  const businessId = req.auth!.businessId!
  const [wallet, employees, transactions, fraudFlags] = await Promise.all([
    prisma.wallet.findFirst({ where: { businessId } }),
    prisma.employee.count({ where: { businessId, status: 'ACTIVE' } }),
    prisma.transaction.findMany({ where: { businessId }, orderBy: { createdAt: 'desc' }, take: 25 }),
    prisma.fraudFlag.findMany({ where: { businessId, resolved: false }, orderBy: { createdAt: 'desc' }, take: 10 }),
  ])
  res.json({ wallet, activeEmployees: employees, liveTransactions: transactions, fraudFlags })
})

businessRouter.get('/capability-check', requireRole('OWNER', 'ADMIN'), async (req, res) => {
  const businessId = req.auth!.businessId ?? z.string().parse(req.query.businessId)
  const [business, wallet, activeEmployees, nfcEmployees, limits, fraudFlags, trustedDevices] = await Promise.all([
    prisma.business.findUnique({
      where: { id: businessId },
      include: { owner: true },
    }),
    prisma.wallet.findFirst({ where: { businessId } }),
    prisma.employee.count({ where: { businessId, status: 'ACTIVE' } }),
    prisma.employee.count({ where: { businessId, status: 'ACTIVE', nfcEnabled: true } }),
    prisma.paymentLimit.findMany({ where: { businessId } }),
    prisma.fraudFlag.count({ where: { businessId, resolved: false, severity: { in: ['HIGH', 'CRITICAL'] } } }),
    prisma.device.count({
      where: {
        trusted: true,
        user: {
          OR: [
            { ownedBusinesses: { some: { id: businessId } } },
            { employeeProfile: { businessId, status: 'ACTIVE' } },
          ],
        },
      },
    }),
  ])

  if (!business) return res.status(404).json({ error: 'Business not found' })

  const perTransactionLimit = limits.find((limit: { period: string }) => limit.period === 'PER_TRANSACTION')
  const dailyLimit = limits.find((limit: { period: string }) => limit.period === 'DAILY')
  const blockers = [
    business.status !== 'ACTIVE' ? 'Business must be active' : undefined,
    business.kycStatus !== 'APPROVED' ? 'Business KYC must be approved before production payments' : undefined,
    !wallet || wallet.status !== 'ACTIVE' ? 'Business wallet must be active' : undefined,
    activeEmployees < 1 ? 'Create at least one active employee receive-only profile' : undefined,
    nfcEmployees < 1 ? 'Enable NFC for at least one owner or employee receiver' : undefined,
    !perTransactionLimit ? 'Configure NGN 100,000 per-transaction limit' : undefined,
    !dailyLimit ? 'Configure NGN 500,000 daily limit' : undefined,
    fraudFlags > 0 ? 'Resolve high or critical fraud flags' : undefined,
    trustedDevices < 1 ? 'Register at least one trusted owner or employee device' : undefined,
  ].filter(Boolean)

  const providerWarnings = [
    !process.env.NFC_PROVIDER_ENABLED || process.env.NFC_PROVIDER_ENABLED === 'false'
      ? 'NFC payment provider is not enabled; sessions will remain in provider-required mode'
      : undefined,
    process.env.PAYMENT_PROVIDER === 'provider_not_configured'
      ? 'Configure a PCI-compliant provider such as Flutterwave, Paystack, Monnify, Interswitch, or NIBSS Tap-to-Pay'
      : undefined,
  ].filter(Boolean)

  res.json({
    businessId,
    canUseBusinessAccount: blockers.length === 0,
    canReceiveNfcPayments: blockers.length === 0 && providerWarnings.length === 0,
    canEmployeesVerifyPayments: activeEmployees > 0 && business.status === 'ACTIVE',
    checks: {
      businessStatus: business.status,
      kycStatus: business.kycStatus,
      walletStatus: wallet?.status ?? 'MISSING',
      activeEmployees,
      nfcEnabledEmployees: nfcEmployees,
      trustedDevices,
      unresolvedHighRiskFraudFlags: fraudFlags,
      perTransactionLimit: perTransactionLimit?.amount ?? null,
      dailyLimit: dailyLimit?.amount ?? null,
    },
    blockers,
    warnings: providerWarnings,
    securityRule:
      'Employee devices must never collect customer ATM PINs. PIN or biometric authorization must happen on the customer device or a PCI-compliant provider secure input.',
  })
})
