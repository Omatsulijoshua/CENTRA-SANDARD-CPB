import { env } from '../config/env.js'

export function scoreFraud(input: {
  amount: number
  dailyTotal: number
  rootedDevice?: boolean
  emulator?: boolean
  locationMismatch?: boolean
  rapidTransactions?: boolean
}) {
  let score = 0
  if (input.amount > env.MAX_TRANSACTION_AMOUNT) score += 60
  if (input.dailyTotal + input.amount > env.MAX_DAILY_EMPLOYEE_AMOUNT) score += 70
  if (input.rootedDevice) score += 35
  if (input.emulator) score += 30
  if (input.locationMismatch) score += 25
  if (input.rapidTransactions) score += 25
  return Math.min(score, 100)
}

export function isBlockedByLimits(amount: number, dailyTotal: number) {
  return amount > env.MAX_TRANSACTION_AMOUNT || dailyTotal + amount > env.MAX_DAILY_EMPLOYEE_AMOUNT
}
