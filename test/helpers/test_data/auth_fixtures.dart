import 'package:kise/features/auth/domain/auth_models.dart';
import 'package:kise/features/auth/presentation/state/auth_notifier.dart';

const testUser = AuthUser(
  id: 'user-test-001',
  email: 'test@kise.app',
  firstName: 'Abel',
  lastName: 'Bekele',
  university: 'AAU',
  department: 'CS',
  currency: 'ETB',
  preferredLanguage: 'English',
  themeMode: 'system',
);

const testTokens = AuthTokens(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresIn: 3600,
);

const testSession = AuthSession(user: testUser, tokens: testTokens);

const authenticatedState = AuthState.authenticated(user: testUser);
const unauthenticatedState = AuthState.unauthenticated();
const loadingState = AuthState.loading();