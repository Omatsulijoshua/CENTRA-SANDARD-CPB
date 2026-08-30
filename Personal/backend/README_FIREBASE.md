# Firebase-backed backend (optional)

Your Flutter app + admin dashboard now use Firebase Auth + Firestore directly.
This Node backend is kept as an **optional** REST layer that mirrors the same Firestore data model
and can be used for server-side operations (admin actions, webhooks, integrations).

## Setup

1) Copy `backend/.env.example` to `backend/.env`
2) Create a Firebase **service account** JSON and set:
   - `FIREBASE_SERVICE_ACCOUNT_FILE="C:\\path\\to\\serviceAccount.json"`
3) Start:
   - `cd backend`
   - `npm start`

## Auth

Send a Firebase ID token:
- Header: `Authorization: Bearer <firebase_id_token>`

## Admin access

Admin checks use Firestore:
- Collection `admins`
- Document id = admin user's UID (`admins/{uid}`)

## Endpoints (Firebase mode)

- `GET /health`
- `GET /api/user/profile`
- `GET /api/transactions`
- `POST /api/transactions/send`
- `POST /api/banks/resolve`
- `GET /api/cards`
- `POST /api/cards/order`
- `GET /api/card-orders`
- `GET /api/linked-bank-cards`
- `POST /api/linked-bank-cards`
- `PATCH /api/linked-bank-cards/:id`
- `POST /api/payment-intents/nfc`

Admin:
- `GET /api/admin/users`
- `GET /api/admin/transactions`
- `GET /api/admin/stats`
- `PATCH /api/admin/users/:uid/kyc`
- `POST /api/admin/users/:uid/balance`
- `GET /api/admin/cards`
- `GET /api/admin/card-orders`
- `GET /api/admin/linked-bank-cards`
- `GET /api/admin/payment-intents`
- `PATCH /api/admin/payment-intents/:id`

## NFC/POS tap-to-pay

The backend stores provider-ready `paymentIntents` for NFC POS payments. Real EMV tap-to-pay still requires an issuer/tokenization/HCE provider; set `config/cardPayments.tapToPayProviderEnabled=true` and `providerName` after integrating that provider.
