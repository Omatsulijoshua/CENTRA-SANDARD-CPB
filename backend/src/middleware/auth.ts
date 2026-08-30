import type { NextFunction, Request, Response } from 'express'
import jwt from 'jsonwebtoken'
import { env } from '../config/env.js'

export type AuthRole = 'OWNER' | 'EMPLOYEE' | 'ADMIN'

export interface AuthUser {
  id: string
  role: AuthRole
  businessId?: string
  employeeId?: string
}

declare global {
  namespace Express {
    interface Request {
      auth?: AuthUser
    }
  }
}

export function signAccessToken(user: AuthUser) {
  return jwt.sign(user, env.JWT_ACCESS_SECRET, { expiresIn: '15m' })
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.startsWith('Bearer ')
    ? req.headers.authorization.slice(7)
    : undefined
  if (!token) return res.status(401).json({ error: 'Missing bearer token' })
  try {
    req.auth = jwt.verify(token, env.JWT_ACCESS_SECRET) as AuthUser
    next()
  } catch {
    return res.status(401).json({ error: 'Invalid token' })
  }
}

export function requireRole(...roles: AuthRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.auth || !roles.includes(req.auth.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' })
    }
    next()
  }
}
