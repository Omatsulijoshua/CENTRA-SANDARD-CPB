import rateLimit from 'express-rate-limit'
import type { NextFunction, Request, Response } from 'express'

export const apiRateLimit = rateLimit({
  windowMs: 60_000,
  limit: 120,
  standardHeaders: true,
  legacyHeaders: false,
})

export function requireDeviceFingerprint(req: Request, res: Response, next: NextFunction) {
  const fingerprint = req.header('x-device-fingerprint')
  if (!fingerprint) return res.status(400).json({ error: 'Missing device fingerprint' })
  next()
}

export function requestSigningGuard(req: Request, res: Response, next: NextFunction) {
  const signature = req.header('x-request-signature')
  if (process.env.NODE_ENV === 'production' && !signature) {
    return res.status(401).json({ error: 'Missing request signature' })
  }
  next()
}
