-- 004_create_allowance_settings.sql
-- Monthly student allowance budget configuration per user.

CREATE TABLE IF NOT EXISTS allowance_settings (
  user_id TEXT PRIMARY KEY,
  monthly_amount REAL NOT NULL DEFAULT 0
    CHECK (monthly_amount >= 0),
  cycle_start_day INTEGER NOT NULL DEFAULT 1
    CHECK (cycle_start_day >= 1 AND cycle_start_day <= 28),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_allowance_settings_user_id
  ON allowance_settings(user_id);