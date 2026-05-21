CREATE TABLE IF NOT EXISTS goal_deposits (
  id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  amount REAL NOT NULL CHECK (amount > 0),
  source TEXT NOT NULL,
  account_id TEXT,
  deposited_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (goal_id) REFERENCES goals(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES payment_accounts(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_goal_deposits_goal_id
  ON goal_deposits(goal_id);

CREATE INDEX IF NOT EXISTS idx_goal_deposits_user_id
  ON goal_deposits(user_id);

CREATE INDEX IF NOT EXISTS idx_goal_deposits_deposited_at
  ON goal_deposits(user_id, deposited_at);