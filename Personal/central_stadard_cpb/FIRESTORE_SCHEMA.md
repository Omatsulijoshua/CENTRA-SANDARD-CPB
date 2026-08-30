# Firestore collections used (mobile + admin)

This app now uses Firebase Auth + Firestore.

## `admins/{uid}`

Create a document whose **ID is the Firebase Auth UID** of an admin user.
The admin dashboard checks this document to allow access.

## `users/{uid}`

User profile document (created on signup).

Suggested fields:
- `name` (string)
- `email` (string)
- `phone` (string)
- `username` (string)
- `accountNumber` (string, 10 digits)
- `balance` (number)
- `emailVerified` (bool)
- `mobileVerified` (bool)
- `kycStatus` (string: `unverified|pending|verified`)
- `banned` (bool)
- `deleted` (bool)
- `language` (string, e.g. `en`)
- `notificationSettings` (map: `push|email|sms|promo` -> bool)
- `biometricPreference` (string: `off|face|fingerprint|device`)
- `fcmTokens` (map token -> timestamp)
- `createdAt` / `updatedAt` (timestamp)
- `totals` (map of totals used by admin user detail)

## `transactions/{id}`

Per-user transaction feed items.

Fields:
- `userId` (string) – owner of this feed item
- `direction` (string: `debit|credit`)
- `type` (string: e.g. `send_money`, `admin_credit`)
- `amount` (number)
- `counterpartyUserId` (string, optional)
- `counterpartyAccount` (string, optional)
- `counterpartyName` (string, optional)
- `reference` (string, optional)
- `createdAt` (timestamp)

## `companies/{id}`

Admin-managed utility bill companies.

Fields:
- `name`, `category`, `charge`, `status`
- `createdAt`

## `billCategories/{id}`

Admin-managed bill categories.

Fields:
- `name`, `status`, `createdAt`

## `config/chargeSettings`

Admin-managed global charges:
- `sendMoneyCharge`, `bankTransferCharge`, `airtimeCharge`, `utilityBillCharge`, `educationFeeCharge`

## `notifications/{id}`

Admin queues a notification document here. Delivery should be handled by Cloud Functions/FCM.

Fields:
- `title`, `body`, `audience`, `status`, `createdAt`

## `appBanners/{id}`

Home-screen banner ads managed by admin.

Fields:
- `title`, `subtitle`, `imageUrl`, `actionUrl`, `active`, `priority`, `createdAt`, `updatedAt`

## `cards/{id}`

Virtual and physical ATM cards.

Fields:
- `userId`, `childId` (optional), `cardType` (`virtual|physical`), `maskedPan`, `holderName`, `status`, `limit`, `createdAt`

## `cardOrders/{id}`

Card order queue.

Fields:
- `userId`, `childId` (optional), `cardType`, `holderName`, `deliveryAddress`, `status`, `createdAt`, `updatedAt`

## `linkedBankCards/{id}`

User-added external bank cards used as selectable payment sources.

Fields:
- `userId`, `bankName`, `holderName`, `network`, `last4`, `maskedPan`, `expiryMonth`, `expiryYear`
- `status` (`active|disabled`), `tokenStatus` (`not_tokenized|pending|tokenized|failed`)
- `defaultForPayment` (bool), `createdAt`, `updatedAt`

Store only masked card data in Firestore. Real PAN/CVV/tokenization must be handled by a PCI-compliant card processor.

## `paymentIntents/{id}`

NFC/POS payment authorization intents.

Fields:
- `userId`, `sourceType` (`issued_card|linked_bank_card`), `cardId`, `linkedCardId`
- `amount`, `currency`, `channel` (`nfc_pos`), `authMethod` (`biometric|pin`)
- `status` (`authorized_waiting_for_tap|provider_required|processing|succeeded|failed|cancelled`)
- `provider`, `providerReference`, `createdAt`, `authorizedAt`, `updatedAt`

Live POS tap-to-pay requires an approved issuer/tokenization/HCE provider. The app creates provider-ready intents and should hand them to that provider when configured.

## `children/{id}`

Parent-created child accounts with simple child sign in.

Fields:
- `parentUserId`, `name`, `username`, `pin`, `balance`, `dailyLimit`, `cardLimit`, `transferLimit`, `status`, `createdAt`, `updatedAt`

## `childTransactions/{id}`

Child account spending feed.

Fields:
- `childId`, `parentUserId`, `type`, `amount`, `merchant`, `status`, `createdAt`

## `supportTickets/{id}`

User support tickets.

Fields:
- `userId`, `subject`, `priority`, `message`, `status`, `createdAt`
