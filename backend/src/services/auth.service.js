const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../config');
const UserModel = require('../models/User.model');
const RefreshTokenModel = require('../models/RefreshToken.model');

function createHttpError(statusCode, code, message, details) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  if (details) {
    error.details = details;
  }
  return error;
}

function getAccessTokenExpiresInSeconds() {
  const value = config.jwt.accessExpiresIn;
  if (value.endsWith('h')) {
    return Number(value.slice(0, -1)) * 3600;
  }
  if (value.endsWith('m')) {
    return Number(value.slice(0, -1)) * 60;
  }
  if (value.endsWith('s')) {
    return Number(value.slice(0, -1));
  }
  return 3600;
}

function buildPublicUser(user) {
  return {
    id: user.id,
    email: user.email,
    firstName: user.firstName,
    lastName: user.lastName,
    phone: user.phone,
    username: user.username,
    university: user.university,
    department: user.department,
    currency: user.currency,
    createdAt: user.createdAt,
  };
}

async function issueTokenPair(user) {
  const accessToken = jwt.sign(
    {
      sub: user.id,
      email: user.email,
    },
    config.jwt.accessSecret,
    {
      expiresIn: config.jwt.accessExpiresIn,
    }
  );

  const rawRefreshToken = crypto.randomBytes(48).toString('hex');
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + config.jwt.refreshExpiresInDays);

  await RefreshTokenModel.create(user.id, rawRefreshToken, expiresAt);

  return {
    accessToken,
    refreshToken: rawRefreshToken,
    expiresIn: getAccessTokenExpiresInSeconds(),
  };
}

class AuthService {
  static async register(payload) {
    const existingUser = await UserModel.findByEmail(payload.email);
    if (existingUser) {
      throw createHttpError(409, 'CONFLICT', 'An account with this email already exists');
    }

    const passwordHash = await bcrypt.hash(payload.password, config.bcryptRounds);

    const user = await UserModel.create({
      email: payload.email,
      passwordHash,
      firstName: payload.firstName,
      lastName: payload.lastName,
      phone: payload.phone,
      username: payload.username,
      university: payload.university,
      department: payload.department,
      currency: payload.currency,
      preferredLanguage: payload.preferredLanguage,
      termsAcceptedAt: payload.termsAccepted ? new Date().toISOString() : null,
    });

    const preferences = await UserModel.getPreferences(user.id);
    const tokens = await issueTokenPair(user);

    return {
      user: {
        ...buildPublicUser(user),
        preferredLanguage: preferences.preferredLanguage,
      },
      tokens,
    };
  }

  static async login(payload) {
    const user = await UserModel.findByEmail(payload.email);

    if (!user) {
      throw createHttpError(401, 'UNAUTHORIZED', 'Invalid email or password');
    }

    const passwordMatches = await bcrypt.compare(payload.password, user.passwordHash);

    if (!passwordMatches) {
      throw createHttpError(401, 'UNAUTHORIZED', 'Invalid email or password');
    }

    const preferences = await UserModel.getPreferences(user.id);
    const tokens = await issueTokenPair(user);

    return {
      user: {
        ...buildPublicUser(user),
        preferredLanguage: preferences.preferredLanguage,
      },
      tokens,
    };
  }

  static async refresh(rawRefreshToken) {
    const storedToken = await RefreshTokenModel.findActiveByRawToken(rawRefreshToken);

    if (!storedToken) {
      throw createHttpError(401, 'UNAUTHORIZED', 'Invalid or expired refresh token');
    }

    const user = await UserModel.findById(storedToken.userId);

    if (!user) {
      await RefreshTokenModel.revokeById(storedToken.id);
      throw createHttpError(401, 'UNAUTHORIZED', 'User no longer exists');
    }

    await RefreshTokenModel.revokeById(storedToken.id);

    const preferences = await UserModel.getPreferences(user.id);
    const tokens = await issueTokenPair(user);

    return {
      user: {
        ...buildPublicUser(user),
        preferredLanguage: preferences.preferredLanguage,
      },
      tokens,
    };
  }

  static async logout(rawRefreshToken) {
    if (!rawRefreshToken) {
      return;
    }

    const storedToken = await RefreshTokenModel.findActiveByRawToken(rawRefreshToken);
    if (storedToken) {
      await RefreshTokenModel.revokeById(storedToken.id);
    }
  }
}

module.exports = AuthService;