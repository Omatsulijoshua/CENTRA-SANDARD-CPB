# Centra Standard Business

Centra Standard Business is a secure shared business banking system for African SMEs.

It gives business owners full control while employees can safely receive and verify payments without getting access to withdrawal features, wallet secrets, or sensitive business controls.

## Core problem solved

Small businesses often cannot give staff access to banking apps because of theft risk. Staff also cannot reliably confirm customer payments without calling the owner. Centra Standard Business creates employee receiving profiles with restricted permissions, live owner monitoring, NFC/QR receive mode, and strict transaction controls.

## Monorepo layout

```text
admin_dashboard/
  Flutter web admin dashboard
backend/
  auth-service/
  business-service/
  transaction-service/
  wallet-service/
  notification-service/
  nfc-service/
  security-service/
  kyc-service/
  database/
  firebase/
  docs/
centra_standard_business_app/
  Flutter owner/employee business app
  customer_payment_app/
public_website/
  Static website that mirrors the business app experience
```

## Safety boundary

NFC card and wallet payments must use certified payment SDKs/gateways. The app must never collect a customer ATM PIN inside Flutter. PIN entry belongs on the customer device, an issuer page, or a PCI-compliant secure input supplied by Paystack, Flutterwave, Monnify, Interswitch, NIBSS, or another approved provider.

## Key limits

- Maximum per transaction: NGN 100,000
- Maximum daily employee receiving limit: NGN 500,000
- Employee role: receive-only by default
- Owner role: full business control

## Quick start

Backend:

```bash
cd backend
npm install
npm run dev
```

Business app:

```bash
cd centra_standard_business_app
flutter pub get
flutter run
```

Admin web:

```bash
cd admin_dashboard
flutter pub get
flutter run -d chrome
```

Public website:

```bash
cd public_website
python -m http.server 8080
```
