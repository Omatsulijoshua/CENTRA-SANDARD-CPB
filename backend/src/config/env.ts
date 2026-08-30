import 'dotenv/config'
import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.string().default('development'),
  PORT: z.coerce.number().default(4100),
  DATABASE_URL: z.string().default('postgresql://postgres:postgres@localhost:5432/centra_business'),
  REDIS_URL: z.string().default('redis://localhost:6379'),
  JWT_ACCESS_SECRET: z.string().default('dev_access_secret'),
  JWT_REFRESH_SECRET: z.string().default('dev_refresh_secret'),
  NFC_PROVIDER_ENABLED: z.coerce.boolean().default(false),
  PAYMENT_PROVIDER: z.string().default('provider_not_configured'),
  MAX_TRANSACTION_AMOUNT: z.coerce.number().default(100000),
  MAX_DAILY_EMPLOYEE_AMOUNT: z.coerce.number().default(500000),
})

export const env = envSchema.parse(process.env)
