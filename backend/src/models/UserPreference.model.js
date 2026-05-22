const db = require('../config/database');

const USER_PREFERENCES_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS user_preferences (
    user_id TEXT PRIMARY KEY,
    preferred_language TEXT NOT NULL DEFAULT 'English'
      CHECK (preferred_language IN ('English', 'Amharic')),
    theme_mode TEXT NOT NULL DEFAULT 'system'
      CHECK (theme_mode IN ('light', 'dark', 'system')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

const ALLOWED_LANGUAGES = ['English', 'Amharic'];
const ALLOWED_THEME_MODES = ['light', 'dark', 'system'];

class UserPreferenceModel {
  static get allowedLanguages() {
    return ALLOWED_LANGUAGES;
  }

  static get allowedThemeModes() {
    return ALLOWED_THEME_MODES;
  }

  static async createTable() {
    await db.run(USER_PREFERENCES_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_user_preferences_language ON user_preferences(preferred_language);'
    );
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_user_preferences_theme ON user_preferences(theme_mode);'
    );
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      userId: row.user_id,
      preferredLanguage: row.preferred_language,
      themeMode: row.theme_mode,
      updatedAt: row.updated_at,
    };
  }

  static async findByUserId(userId) {
    const row = await db.get(
      `
        SELECT user_id, preferred_language, theme_mode, updated_at
        FROM user_preferences
        WHERE user_id = ?
        LIMIT 1;
      `,
      [userId]
    );

    return UserPreferenceModel.mapRow(row);
  }

  static async createDefault(userId, preferredLanguage = 'English') {
    const now = new Date().toISOString();

    await db.run(
      `
        INSERT INTO user_preferences (user_id, preferred_language, theme_mode, updated_at)
        VALUES (?, ?, 'system', ?);
      `,
      [userId, preferredLanguage, now]
    );

    return UserPreferenceModel.findByUserId(userId);
  }

  static async update(userId, data) {
    const existing = await UserPreferenceModel.findByUserId(userId);
    if (!existing) {
      await UserPreferenceModel.createDefault(
        userId,
        data.preferredLanguage || 'English'
      );
    }

    const now = new Date().toISOString();
    const current = await UserPreferenceModel.findByUserId(userId);

    await db.run(
      `
        UPDATE user_preferences
        SET
          preferred_language = ?,
          theme_mode = ?,
          updated_at = ?
        WHERE user_id = ?;
      `,
      [
        data.preferredLanguage !== undefined
          ? data.preferredLanguage
          : current.preferredLanguage,
        data.themeMode !== undefined ? data.themeMode : current.themeMode,
        now,
        userId,
      ]
    );

    return UserPreferenceModel.findByUserId(userId);
  }
}

module.exports = UserPreferenceModel;