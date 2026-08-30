# Security and Compliance Notes

## Non-negotiable payment rules

- Never store card PIN, CVV, or full PAN.
- Never ask a customer to type ATM PIN into an employee or business owner phone.
- Use tokenized card payments through certified payment processors.
- Use provider webhooks for final settlement truth.

## Anti-theft controls

- Employees are receive-only by default.
- NGN 100,000 max per transaction.
- NGN 500,000 max daily employee receiving limit.
- Velocity checks, device fingerprint, rooted device flag, emulator flag, and geo mismatch signals feed fraud scoring.
- Owners can suspend employees, freeze NFC, reset devices, and view all activity.

## Audit log coverage

Track:

- Login attempts
- Device changes
- Employee creation and suspension
- Permission changes
- NFC sessions
- Transactions
- Withdrawal attempts
- Fraud flags
- KYC actions

## Compliance posture

- PCI-DSS principles: card data is tokenized and handled by certified providers.
- NDPR: collect minimum personal data, protect KYC files, expose data access controls.
- App Check: enable before production Firestore/Functions use.

