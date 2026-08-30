CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('OWNER', 'EMPLOYEE', 'ADMIN');
CREATE TYPE business_status AS ENUM ('ACTIVE', 'FROZEN', 'SUSPENDED', 'CLOSED');
CREATE TYPE kyc_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE employee_status AS ENUM ('ACTIVE', 'SUSPENDED', 'FROZEN', 'REMOVED');
CREATE TYPE transaction_status AS ENUM ('INITIATED', 'PENDING_PROVIDER', 'AUTHORIZED', 'SUCCEEDED', 'FAILED', 'CANCELLED', 'FLAGGED');

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT UNIQUE,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  full_name TEXT NOT NULL,
  role user_role NOT NULL,
  password_hash TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE businesses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  cac_number TEXT,
  category TEXT NOT NULL,
  tax_id TEXT,
  address TEXT NOT NULL,
  kyc_status kyc_status NOT NULL DEFAULT 'PENDING',
  status business_status NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id),
  name TEXT NOT NULL,
  address TEXT
);

CREATE TABLE employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id),
  business_id UUID NOT NULL REFERENCES businesses(id),
  branch_id UUID REFERENCES branches(id),
  display_name TEXT NOT NULL,
  receiving_account TEXT NOT NULL UNIQUE,
  nfc_receiver_id TEXT NOT NULL UNIQUE,
  qr_payload TEXT NOT NULL,
  status employee_status NOT NULL DEFAULT 'ACTIVE',
  nfc_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  transaction_limit NUMERIC(14,2) NOT NULL DEFAULT 100000,
  daily_limit_amount NUMERIC(14,2) NOT NULL DEFAULT 500000,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE employee_permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  employee_id UUID NOT NULL REFERENCES employees(id),
  permission TEXT NOT NULL,
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id),
  currency TEXT NOT NULL DEFAULT 'NGN',
  balance NUMERIC(14,2) NOT NULL DEFAULT 0,
  ledger_balance NUMERIC(14,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id),
  employee_id UUID REFERENCES employees(id),
  type TEXT NOT NULL,
  channel TEXT NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'NGN',
  status transaction_status NOT NULL,
  provider TEXT,
  provider_ref TEXT,
  risk_score INT NOT NULL DEFAULT 0,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE nfc_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL UNIQUE REFERENCES transactions(id),
  business_id UUID NOT NULL REFERENCES businesses(id),
  employee_id UUID REFERENCES employees(id),
  receiver_device_id UUID,
  status TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  fingerprint TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL,
  model TEXT,
  trusted BOOLEAN NOT NULL DEFAULT FALSE,
  rooted BOOLEAN NOT NULL DEFAULT FALSE,
  emulator BOOLEAN NOT NULL DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_user_id UUID REFERENCES users(id),
  business_id UUID REFERENCES businesses(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id TEXT,
  ip_address TEXT,
  device_id TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fraud_flags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID REFERENCES businesses(id),
  employee_id UUID REFERENCES employees(id),
  transaction_id UUID REFERENCES transactions(id),
  severity TEXT NOT NULL,
  reason TEXT NOT NULL,
  score INT NOT NULL,
  resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID REFERENCES businesses(id),
  user_id UUID REFERENCES users(id),
  channel TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'QUEUED',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id),
  type TEXT NOT NULL,
  file_url TEXT NOT NULL,
  status kyc_status NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payment_limits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES businesses(id),
  scope TEXT NOT NULL,
  amount NUMERIC(14,2) NOT NULL,
  period TEXT NOT NULL
);

CREATE INDEX idx_transactions_business_created ON transactions (business_id, created_at DESC);
CREATE INDEX idx_transactions_employee_created ON transactions (employee_id, created_at DESC);
CREATE INDEX idx_audit_business_created ON audit_logs (business_id, created_at DESC);
CREATE INDEX idx_fraud_business_resolved ON fraud_flags (business_id, resolved);
