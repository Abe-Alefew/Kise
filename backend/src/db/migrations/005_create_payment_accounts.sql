-- 005_create_payment_accounts.sql
-- Stores user-linked bank, wallet, and mobile-money accounts.

CREATE TABLE IF NOT EXISTS payment_accounts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('Bank', 'Mobile Money', 'Wallet', 'Other')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_payment_accounts_user_id
  ON payment_accounts(user_id);

CREATE INDEX IF NOT EXISTS idx_payment_accounts_user_type
  ON payment_accounts(user_id, type);
