const fs = require("fs");
const path = require("path");
const sqlite3 = require("sqlite3");
const config = require("./index");

class Database {
  constructor() {
    this.db = null;
    this.initialized = false;
  }

  connect() {
    if (this.db) {
      return Promise.resolve(this.db);
    }

    const dbDir = path.dirname(config.dbPath);
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }

    return new Promise((resolve, reject) => {
      this.db = new sqlite3.Database(config.dbPath, (err) => {
        if (err) {
          reject(err);
          return;
        }

        this.db.run("PRAGMA foreign_keys = ON", (pragmaErr) => {
          if (pragmaErr) {
            reject(pragmaErr);
            return;
          }
          resolve(this.db);
        });
      });
    });
  }

  run(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(sql, params, function onRun(err) {
        if (err) {
          reject(err);
          return;
        }
        resolve({ lastID: this.lastID, changes: this.changes });
      });
    });
  }

  get(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.get(sql, params, (err, row) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(row);
      });
    });
  }

  all(sql, params = []) {
    return new Promise((resolve, reject) => {
      this.db.all(sql, params, (err, rows) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(rows);
      });
    });
  }

  async initialize() {
    if (this.initialized) {
      return;
    }

    await this.connect();

    const UserModel = require("../models/User.model");
    const RefreshTokenModel = require("../models/RefreshToken.model");
    const DebtModel = require("../models/Debt.model");
    const DebtPaymentModel = require("../models/DebtPayment.model");
    const UserPreferenceModel = require("../models/UserPreference.model");
    const AllowanceModel = require("../models/Allowance.model");
    const TransactionModel = require("../models/Transaction.model");

    await UserModel.createTable();
    await UserModel.createPreferencesTable();
    await UserModel.createAllowanceTable();
    await RefreshTokenModel.createTable();
    await DebtModel.createTable();
    await DebtPaymentModel.createTable();
    await UserPreferenceModel.createTable();
    await AllowanceModel.createTable();
    await TransactionModel.createTable();

    this.initialized = true;
    console.log("✅ Phase 4 Database Tables & Transactions Initialized.");
  }

  close() {
    if (!this.db) {
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      this.db.close((err) => {
        if (err) {
          reject(err);
          return;
        }
        this.db = null;
        this.initialized = false;
        resolve();
      });
    });
  }
}

module.exports = new Database();