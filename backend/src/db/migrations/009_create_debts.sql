CREATE TABLE IF NOT EXISTS debts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  person_name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('lent', 'borrowed')),
  total_amount REAL NOT NULL CHECK (total_amount >= 0),
  paid_amount REAL NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
  debt_date TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CHECK (paid_amount <= total_amount)
);

CREATE INDEX IF NOT EXISTS idx_debts_user_id
  ON debts(user_id);

CREATE INDEX IF NOT EXISTS idx_debts_user_type
  ON debts(user_id, type);

CREATE INDEX IF NOT EXISTS idx_debts_user_date
  ON debts(user_id, debt_date);

CREATE INDEX IF NOT EXISTS idx_debts_user_person
  ON debts(user_id, person_name);