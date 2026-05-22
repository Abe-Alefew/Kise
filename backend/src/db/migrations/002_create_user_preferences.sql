-- 002_create_user_preferences.sql
-- Per-user UI and localization preferences.

CREATE TABLE IF NOT EXISTS user_preferences (
  user_id TEXT PRIMARY KEY,
  preferred_language TEXT NOT NULL DEFAULT 'English'
    CHECK (preferred_language IN ('English', 'Amharic')),
  theme_mode TEXT NOT NULL DEFAULT 'system'
    CHECK (theme_mode IN ('light', 'dark', 'system')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_preferences_language
  ON user_preferences(preferred_language);

CREATE INDEX IF NOT EXISTS idx_user_preferences_theme
  ON user_preferences(theme_mode);