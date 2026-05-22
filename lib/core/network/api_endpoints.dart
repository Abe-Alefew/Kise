abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '<http://10.0.2.2:3000/api/v1>',
  );

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String usersMe = '/users/me';

  static const String settingsAllowance = '/settings/allowance';
  static const String settingsPreferences = '/settings/preferences';
  static const String settingsAccounts = '/settings/accounts';

  static const String transactions = '/transactions';
  static const String transactionsSummary = '/transactions/summary';
  static const String transactionsAnalytics = '/transactions/analytics';

  static const String goals = '/goals';
  static const String debts = '/debts';
  static const String debtsSummary = '/debts/summary';
  static const String debtsAnalytics = '/debts/analytics';

  static const String dashboardHome = '/dashboard/home';
  static const String health = '/health';
}