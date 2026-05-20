CREATE TABLE IF NOT EXISTS goal_deposits (
  id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  amount REAL NOT NULL,
  source TEXT NOT NULL,
  account_id TEXT,
  deposited_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES payment_accounts (id) ON DELETE SET NULL
);
