const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

const USERS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    username TEXT,
    university TEXT NOT NULL,
    department TEXT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'ETB',
    terms_accepted_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`;

const USER_PREFERENCES_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS user_preferences (
    user_id TEXT PRIMARY KEY,
    preferred_language TEXT NOT NULL DEFAULT 'English',
    theme_mode TEXT NOT NULL DEFAULT 'system',
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

const ALLOWANCE_SETTINGS_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS allowance_settings (
    user_id TEXT PRIMARY KEY,
    monthly_amount REAL NOT NULL DEFAULT 0,
    cycle_start_day INTEGER NOT NULL DEFAULT 1,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );
`;

class UserModel {
  static async createTable() {
    await db.run(USERS_TABLE_SQL);
    await db.run(
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);'
    );
  }

  static async createPreferencesTable() {
    await db.run(USER_PREFERENCES_TABLE_SQL);
  }

  static async createAllowanceTable() {
    await db.run(ALLOWANCE_SETTINGS_TABLE_SQL);
  }

  static mapRow(row) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      email: row.email,
      passwordHash: row.password_hash,
      firstName: row.first_name,
      lastName: row.last_name,
      phone: row.phone,
      username: row.username,
      university: row.university,
      department: row.department,
      currency: row.currency,
      termsAcceptedAt: row.terms_accepted_at,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  static mapPublicUser(row) {
    const user = UserModel.mapRow(row);
    if (!user) {
      return null;
    }

    delete user.passwordHash;
    return user;
  }

  static async create(userData) {
    const id = uuidv4();
    const now = new Date().toISOString();

    await db.run(
      `
        INSERT INTO users (
          id,
          email,
          password_hash,
          first_name,
          last_name,
          phone,
          username,
          university,
          department,
          currency,
          terms_accepted_at,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      `,
      [
        id,
        userData.email.toLowerCase().trim(),
        userData.passwordHash,
        userData.firstName.trim(),
        userData.lastName.trim(),
        userData.phone ? userData.phone.trim() : null,
        userData.username ? userData.username.trim() : null,
        userData.university.trim(),
        userData.department.trim(),
        userData.currency || 'ETB',
        userData.termsAcceptedAt || now,
        now,
        now,
      ]
    );

    await db.run(
      `
        INSERT INTO user_preferences (user_id, preferred_language, theme_mode, updated_at)
        VALUES (?, ?, 'system', ?);
      `,
      [id, userData.preferredLanguage || 'English', now]
    );

    await db.run(
      `
        INSERT INTO allowance_settings (user_id, monthly_amount, cycle_start_day, updated_at)
        VALUES (?, 0, 1, ?);
      `,
      [id, now]
    );

    return UserModel.findById(id);
  }

  static async findByEmail(email) {
    const row = await db.get(
      `
        SELECT
          id,
          email,
          password_hash,
          first_name,
          last_name,
          phone,
          username,
          university,
          department,
          currency,
          terms_accepted_at,
          created_at,
          updated_at
        FROM users
        WHERE email = ? COLLATE NOCASE
        LIMIT 1;
      `,
      [email.toLowerCase().trim()]
    );

    return UserModel.mapRow(row);
  }

  static async findById(id) {
    const row = await db.get(
      `
        SELECT
          id,
          email,
          password_hash,
          first_name,
          last_name,
          phone,
          username,
          university,
          department,
          currency,
          terms_accepted_at,
          created_at,
          updated_at
        FROM users
        WHERE id = ?
        LIMIT 1;
      `,
      [id]
    );

    return UserModel.mapRow(row);
  }

  static async findPublicById(id) {
    const user = await UserModel.findById(id);
    if (!user) {
      return null;
    }

    delete user.passwordHash;
    return user;
  }

  static async getPreferences(userId) {
    const row = await db.get(
      `
        SELECT preferred_language, theme_mode, updated_at
        FROM user_preferences
        WHERE user_id = ?
        LIMIT 1;
      `,
      [userId]
    );

    if (!row) {
      return null;
    }

    return {
      preferredLanguage: row.preferred_language,
      themeMode: row.theme_mode,
      updatedAt: row.updated_at,
    };
  }
}

module.exports = UserModel;