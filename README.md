# Centra Banking Platform (Personal & Business)

Welcome to the **Centra Banking Platform** — a unified digital banking ecosystem that supports both **Personal Consumer Banking** and **SME/Business Banking**. 

This repository has been consolidated to run a shared, high-performance PostgreSQL backend with a unified Vite React administration panel.

---

## 🏛️ Project Architecture

```mermaid
graph TD
    subgraph Client Apps
        flutter_personal[Personal Flutter App]
        flutter_business[Business Flutter App]
        admin_react[React Admin Dashboard]
    end

    subgraph Unified Backend (backend)
        express_server[Express server.ts]
        routes_personal[routes/personal.ts /api]
        routes_business[business-service/src/routes.ts]
        routes_nfc[nfc-service/src/routes.ts]
        prisma_client[Prisma Client ORM]
    end

    subgraph Databases & Services
        postgres_db[(PostgreSQL Database)]
        firebase_auth[Firebase Auth Admin SDK]
    end

    flutter_personal -->|Firebase Bearer Token| routes_personal
    flutter_business -->|JWT Bearer Token| routes_business
    admin_react -->|Firebase Bearer Token| routes_personal
    routes_personal --> firebase_auth
    routes_personal --> prisma_client
    routes_business --> prisma_client
    routes_nfc --> prisma_client
    prisma_client --> postgres_db
```

The repository is organized into the following key folders:
1. **`backend/`**: The main Express.js backend server. It serves both business banking services and personal consumer APIs, backed by a unified PostgreSQL database managed through Prisma.
2. **`admin_dashboard/`**: The unified React + Vite administration dashboard. Allows super-admins to monitor statistics, manage users, approve business KYC, issue cards, track NFC payments, and resolve security fraud flags.
3. **`Personal/central_stadard_cpb/`**: The Flutter mobile application designed for personal consumer banking.
4. **`Personal/public_website/`**: Marketing landing pages and public web assets.

---

## 💻 Backend Setup & Running

The backend is built with **TypeScript**, **Express**, and **Prisma ORM**.

### Prerequisites
- Node.js v20+ / v24
- PNPM installed (`npm install -g pnpm`)
- PostgreSQL database instance

### Setup Instructions
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pnpm install
   ```
3. Approve dependency build hooks (Prisma client generation and engines):
   ```bash
   pnpm approve-builds
   # Select all packages (press 'a' then 'Enter'), and confirm 'y'
   ```
4. Configure your `.env` variables:
   Create a `.env` file in `backend/` and configure the following parameters:
   ```env
   # PostgreSQL Connection
   DATABASE_URL="postgresql://username:password@localhost:5432/centra_db?schema=public"

   # Firebase Admin Configuration (For Personal App JWT Verification)
   FIREBASE_SERVICE_ACCOUNT_JSON='{"type": "service_account", "project_id": "...", ...}'

   # Port configuration
   PORT=3000
   ```
5. Apply database tables and generate Prisma Client:
   ```bash
   pnpm run prisma:generate
   ```
6. Start the development server:
   ```bash
   pnpm run dev
   ```

The backend will start on `http://localhost:3000`.
- Business endpoints are mounted under `/auth`, `/businesses`, and `/employees`.
- Personal endpoints are mounted under `/api`.

---

## 🖥️ Admin Dashboard Setup & Running

The Admin Dashboard is built with **React**, **Vite**, and **Lucide Icons**.

### Setup Instructions
1. Navigate to the admin dashboard directory:
   ```bash
   cd admin_dashboard
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure your `.env` variables:
   Create a `.env` file in `admin_dashboard/`:
   ```env
   # Firebase Credentials for Dashboard Authentication
   VITE_FIREBASE_API_KEY="your-api-key"
   VITE_FIREBASE_AUTH_DOMAIN="your-app.firebaseapp.com"
   VITE_FIREBASE_PROJECT_ID="your-project-id"
   VITE_FIREBASE_STORAGE_BUCKET="your-app.appspot.com"
   VITE_FIREBASE_MESSAGING_SENDER_ID="sender-id"
   VITE_FIREBASE_APP_ID="app-id"

   # Consolidated Backend Base URL
   VITE_API_URL="http://localhost:3000/api"
   ```
4. Start the dashboard in development mode:
   ```bash
   npm run dev
   ```

The dashboard will open on `http://localhost:5173`.

---

## 🗄️ Database Schema & Models

Data is managed inside PostgreSQL via [schema.prisma](file:///c:/Users/SirBill's/Desktop/CENTRA-SANDARD-CPB-main/CENTRA-SANDARD-CPB-main/Bussiness/backend/prisma/schema.prisma).

Key Models:
- **`User`**: Tracks all system users (personal users, business owners, and employees). Includes `balance`, `accountNumber` (10-digit generated), `kycStatus`, and `role`.
- **`Business`**: Tracks SME corporate accounts, including their `cacNumber`, `taxId`, `category`, and `kycStatus`.
- **`Employee`**: Profiles of business team members authorized to collect NFC/QR payments.
- **`Card` & `CardOrder`**: Manage virtual and physical ATM card issuances.
- **`ChildAccount`**: Accounts linked to parent `User` records with daily limit controls.
- **`Transaction`**: Immutable ledger of transfers, cards spends, and NFC tap payments. Supports optional `businessId` (for SME sales) and direct `userId` links (for consumer transactions).
- **`FraudFlag`**: Tracks security incidents and abnormal transactions flagged for administrator review.

---

## 🔌 API Endpoints Summary

### Personal Banking APIs (`/api`)
- `GET /user/profile` — Fetch details and balance, auto-registers Firebase users.
- `POST /transactions/send` — Make immediate P2P transfers (atomically debits/credits balances).
- `POST /banks/resolve` — Perform counterparty account verification.
- `GET /cards` & `POST /cards/order` — Request virtual or physical cards.
- `GET /children` & `POST /children` — Parent control panel for child cards and limits.

### Business Banking APIs
- `POST /auth/signup-business` — Sign up a new business profile.
- `GET /me` — Retrieve merchant capabilities and status parameters.
- `POST /branches` — Set up sub-office branches.
- `POST /employees` — Add team members to process in-store payments.

### Administrative APIs (`/api/admin`)
- `GET /admin/users` — Search all database accounts.
- `GET /admin/businesses` — Retrieve registered merchant list.
- `PATCH /admin/businesses/:id/kyc` — Approve or reject SME KYC profiles.
- `GET /admin/fraud-flags` — Audit security flags and risk scores.
- `PATCH /admin/fraud-flags/:id/resolve` — Resolve security warnings.
- `POST /admin/users/:uid/balance` — Deposit or withdraw funds as administrative adjustments.
