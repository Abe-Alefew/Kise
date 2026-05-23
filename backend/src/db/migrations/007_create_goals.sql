CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  period TEXT NOT NULL CHECK (
    period IN ('daily', 'weekly', 'monthly', 'yearly', 'one-time')
  ),
  target_amount REAL NOT NULL CHECK (target_amount > 0),
  current_amount REAL NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  due_date TEXT NOT NULL,
  note TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (
    status IN ('active', 'completed', 'canceled')
  ),
  is_locked INTEGER NOT NULL DEFAULT 0 CHECK (is_locked IN (0, 1)),
  completed_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_goals_user_id
  ON goals(user_id);

CREATE INDEX IF NOT EXISTS idx_goals_user_status
  ON goals(user_id, status);

CREATE INDEX IF NOT EXISTS idx_goals_user_due_date
  ON goals(user_id, due_date);

CREATE INDEX IF NOT EXISTS idx_goals_user_period
  ON goals(user_id, period);