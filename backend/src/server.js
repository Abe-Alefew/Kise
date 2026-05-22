const app = require('./app');
const config = require('./config');
const database = require('./config/database');

async function startServer() {
  await database.initialize();

  const server = app.listen(config.port, () => {
    console.log(`Kise API listening on port ${config.port}`);
  });

  const shutdown = async (signal) => {
    console.log(`Received ${signal}. Shutting down...`);
    server.close(async () => {
      await database.close();
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});const app = require('./app');
const config = require('./config');
const database = require('./config/database');

const UserModel = require('./models/User.model');
const RefreshTokenModel = require('./models/RefreshToken.model');
const UserPreferenceModel = require('./models/UserPreference.model');
const AllowanceModel = require('./models/Allowance.model');
const PaymentAccountModel = require('./models/PaymentAccount.model');
const TransactionModel = require('./models/Transaction.model');
const GoalModel = require('./models/Goal.model');
const GoalDepositModel = require('./models/GoalDeposit.model');
const DebtModel = require('./models/Debt.model');
const DebtPaymentModel = require('./models/DebtPayment.model');

async function initializeAllTables() {
  await database.connect();

  await UserModel.createTable();
  await UserModel.createPreferencesTable();
  await UserModel.createAllowanceTable();
  await RefreshTokenModel.createTable();

  await UserPreferenceModel.createTable();
  await AllowanceModel.createTable();
  await PaymentAccountModel.createTable();
  await TransactionModel.createTable();
  await GoalModel.createTable();
  await GoalDepositModel.createTable();
  await DebtModel.createTable();
  await DebtPaymentModel.createTable();

  database.initialized = true;
}

async function startServer() {
  await initializeAllTables();

  const server = app.listen(config.port, () => {
    console.log(`Kise API listening on port ${config.port}`);
    console.log(`Environment: ${config.nodeEnv}`);
    console.log(`Database: ${config.dbPath}`);
  });

  const shutdown = async (signal) => {
    console.log(`Received ${signal}. Shutting down gracefully...`);

    server.close(async () => {
      try {
        await database.close();
        console.log('Database connection closed.');
        process.exit(0);
      } catch (error) {
        console.error('Error during shutdown:', error);
        process.exit(1);
      }
    });

    setTimeout(() => {
      console.error('Forced shutdown after timeout.');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));

  process.on('unhandledRejection', (reason) => {
    console.error('Unhandled promise rejection:', reason);
  });

  process.on('uncaughtException', (error) => {
    console.error('Uncaught exception:', error);
    shutdown('uncaughtException');
  });
}

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});