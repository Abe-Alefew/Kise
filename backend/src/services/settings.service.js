const AllowanceModel = require("../models/Allowance.model");
const PaymentAccountModel = require("../models/PaymentAccount.model");
const UserPreferenceModel = require("../models/UserPreference.model");

class SettingsService {
  async getAllowance(userId) {
    const allowance = await AllowanceModel.findByUserId(userId);
    if (!allowance) return null;
    return {
      monthlyAmount: allowance.monthly_amount,
      cycleStartDay: allowance.cycle_start_day,
      updatedAt: allowance.updated_at
    };
  }

  async updateAllowance(userId, data) {
    const allowance = await AllowanceModel.upsert(userId, data);
    return {
      monthlyAmount: allowance.monthly_amount,
      cycleStartDay: allowance.cycle_start_day,
      updatedAt: allowance.updated_at
    };
  }

  async getAccounts(userId) {
    const accounts = await PaymentAccountModel.findAllByUserId(userId);
    return accounts.map((acc) => ({
      id: acc.id,
      name: acc.name,
      type: acc.type
    }));
  }

  async createAccount(userId, data) {
    const account = await PaymentAccountModel.create(userId, data);
    return {
      id: account.id,
      name: account.name,
      type: account.type
    };
  }

  async deleteAccount(userId, accountId) {
    return PaymentAccountModel.delete(userId, accountId);
  }

  async getPreferences(userId) {
    const prefs = await UserPreferenceModel.findByUserId(userId);
    if (!prefs) return null;
    return {
      preferredLanguage: prefs.preferred_language,
      themeMode: prefs.theme_mode
    };
  }

  async updatePreferences(userId, data) {
    const prefs = await UserPreferenceModel.upsert(userId, data);
    return {
      preferredLanguage: prefs.preferred_language,
      themeMode: prefs.theme_mode
    };
  }
}

module.exports = new SettingsService();
