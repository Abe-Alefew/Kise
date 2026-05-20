const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const requiredInProduction = ['JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET'];

if (process.env.NODE_ENV === 'production') {
  for (const key of requiredInProduction) {
    if (!process.env[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }
}

module.exports = {
  port: Number(process.env.PORT) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  dbPath: process.env.DB_PATH || path.resolve(__dirname, '../../data/kise.db'),
  jwt: {
    accessSecret:
      process.env.JWT_ACCESS_SECRET || 'kise-dev-access-secret-change-in-production',
    refreshSecret:
      process.env.JWT_REFRESH_SECRET || 'kise-dev-refresh-secret-change-in-production',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '1h',
    refreshExpiresInDays: Number(process.env.JWT_REFRESH_EXPIRES_DAYS) || 7,
  },
  bcryptRounds: 10,
};