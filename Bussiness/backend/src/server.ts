import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import { env } from './config/env.js'
import { apiRateLimit, requestSigningGuard } from './middleware/security.js'
import { authRouter } from '../auth-service/src/routes.js'
import { businessRouter } from '../business-service/src/routes.js'
import { employeeRouter } from '../business-service/src/employee-routes.js'
import { transactionRouter } from '../transaction-service/src/routes.js'
import { walletRouter } from '../wallet-service/src/routes.js'
import { nfcRouter } from '../nfc-service/src/routes.js'
import { notificationRouter } from '../notification-service/src/routes.js'
import { securityRouter } from '../security-service/src/routes.js'
import { kycRouter } from '../kyc-service/src/routes.js'
import { personalRouter } from './routes/personal.js'

const app = express()

app.use(helmet())
app.use(cors())
app.use(express.json({ limit: '1mb' }))
app.use(morgan('dev'))
app.use(apiRateLimit)
app.use(requestSigningGuard)

app.get('/health', (_req, res) => {
  res.json({ ok: true, app: 'centra-standard-business', provider: env.PAYMENT_PROVIDER })
})

app.use('/auth', authRouter)
app.use('/businesses', businessRouter)
app.use('/employees', employeeRouter)
app.use('/transactions', transactionRouter)
app.use('/wallet', walletRouter)
app.use('/payments/nfc', nfcRouter)
app.use('/notifications', notificationRouter)
app.use('/security', securityRouter)
app.use('/kyc', kycRouter)
app.use('/api', personalRouter)

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err)
  res.status(500).json({ error: 'Internal server error' })
})

app.listen(env.PORT, () => {
  console.log(`Centra Standard Business backend running on ${env.PORT}`)
})
