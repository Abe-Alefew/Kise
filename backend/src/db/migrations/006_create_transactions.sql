-- 006_create_transactions.sql
-- Income and expense ledger entries per user.

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('Income', 'Expense')),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  amount REAL NOT NULL CHECK (amount > 0),
  transaction_date TEXT NOT NULL,
  account_id TEXT,
  note TEXT,
  icon_key TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  deleted_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES payment_accounts(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id
  ON transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_transactions_user_date
  ON transactions(user_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_transactions_user_type
  ON transactions(user_id, type);

CREATE INDEX IF NOT EXISTS idx_transactions_user_category
  ON transactions(user_id, category);

CREATE INDEX IF NOT EXISTS idx_transactions_user_account
  ON transactions(user_id, account_id);

CREATE INDEX IF NOT EXISTS idx_transactions_active
  ON transactions(user_id, deleted_at);