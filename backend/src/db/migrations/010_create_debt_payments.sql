CREATE TABLE IF NOT EXISTS debt_payments (
  id TEXT PRIMARY KEY,
  debt_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  amount REAL NOT NULL CHECK (amount > 0),
  payment_date TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (debt_id) REFERENCES debts(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt_id
  ON debt_payments(debt_id);

CREATE INDEX IF NOT EXISTS idx_debt_payments_user_id
  ON debt_payments(user_id);

CREATE INDEX IF NOT EXISTS idx_debt_payments_payment_date
  ON debt_payments(user_id, payment_date);