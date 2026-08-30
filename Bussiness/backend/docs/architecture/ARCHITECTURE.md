# Centra Standard Business Architecture

## Apps

- `centra_standard_business_app`: Owner and employee app with two login modes.
- `centra_standard_business_app/customer_payment_app`: Customer-side payment approval shell for secure customer-device authorization.
- `admin_dashboard`: Internal admin console for KYC, AML, fraud, revenue, system health, and freezes.
- `public_website`: Static app-like business website and dashboard preview.

## Backend services

- `auth-service`: owner signup, owner login, employee login, JWT, refresh token plan.
- `business-service`: onboarding, branches, employee profiles, permissions.
- `transaction-service`: unified transaction feed.
- `wallet-service`: business wallets, settlement, withdrawal approval.
- `nfc-service`: NFC receiving sessions and provider-ready tap-to-pay intents.
- `notification-service`: push, email, SMS, voice.
- `security-service`: devices, trusted devices, audit logs.
- `kyc-service`: CAC, BVN, NIN, selfie, utility bill documents.

## NFC payment receiving

Employees and owners can open a dedicated receive page. The backend creates an NFC session with a five-minute expiry, per-transaction and daily limit checks, and fraud scoring.

PIN entry is never handled by merchant Flutter code. Supported production paths:

- Customer Apple Pay / Google Pay biometric on customer device.
- Contactless card via certified Tap-to-Pay SDK.
- Payment gateway secure input / issuer challenge flow.
- Provider webhook confirms final transaction status.

## Role model

- Owner: full business control, employee management, limits, freezes, audit logs.
- Employee: receive money, verify own payments, QR/NFC receive mode, own transaction history.
- Admin: platform compliance, AML, KYC, business freezes.
