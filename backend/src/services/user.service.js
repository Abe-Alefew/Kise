const db = require('../config/database');

function createHttpError(statusCode, code, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
}

async function tableExists(tableName) {
  const row = await db.get(
    `
      SELECT name
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      LIMIT 1;
    `,
    [tableName]
  );

  return Boolean(row);
}

function buildProfile(row, includePreferences) {
  const profile = {
    id: row.id,
    email: row.email,
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

  if (includePreferences) {
    profile.preferences = row.preferred_language
      ? {
          preferredLanguage: row.preferred_language,
          themeMode: row.theme_mode,
          updatedAt: row.preferences_updated_at,
        }
      : null;
  }

  return profile;
}

class UserService {
  static async getUserProfile(userId) {
    if (!userId) {
      throw createHttpError(401, 'UNAUTHORIZED', 'Authentication required');
    }

    const hasPreferences = await tableExists('user_preferences');

    const selectFields = [
      'u.id',
      'u.email',
      'u.first_name',
      'u.last_name',
      'u.phone',
      'u.username',
      'u.university',
      'u.department',
      'u.currency',
      'u.terms_accepted_at',
      'u.created_at',
      'u.updated_at',
    ];

    if (hasPreferences) {
      selectFields.push('p.preferred_language');
      selectFields.push('p.theme_mode');
      selectFields.push('p.updated_at AS preferences_updated_at');
    }

    const joinClause = hasPreferences
      ? 'LEFT JOIN user_preferences p ON p.user_id = u.id'
      : '';

    const row = await db.get(
      `
        SELECT ${selectFields.join(', ')}
        FROM users u
        ${joinClause}
        WHERE u.id = ?
        LIMIT 1;
      `,
      [userId]
    );

    if (!row) {
      throw createHttpError(404, 'NOT_FOUND', 'User not found');
    }

    return buildProfile(row, hasPreferences);
  }

  static async deleteUserAccount(userId) {
    if (!userId) {
      throw createHttpError(401, 'UNAUTHORIZED', 'Authentication required');
    }

    const existing = await db.get(
      'SELECT id FROM users WHERE id = ? LIMIT 1;',
      [userId]
    );

    if (!existing) {
      throw createHttpError(404, 'NOT_FOUND', 'User not found');
    }

    await db.run('BEGIN IMMEDIATE TRANSACTION;');

    try {
      await db.run('DELETE FROM refresh_tokens WHERE user_id = ?;', [userId]);

      const result = await db.run('DELETE FROM users WHERE id = ?;', [userId]);

      if (result.changes === 0) {
        await db.run('ROLLBACK;');
        throw createHttpError(404, 'NOT_FOUND', 'User not found');
      }

      await db.run('COMMIT;');
      return { deleted: true };
    } catch (error) {
      await db.run('ROLLBACK;');
      throw error;
    }
  }
}

module.exports = UserService;
