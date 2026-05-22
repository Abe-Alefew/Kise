import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kise/core/constants/app_constants.dart';
import 'package:kise/core/network/dio_client.dart';
import 'package:kise/core/routing/app_router.dart';
import 'package:kise/features/auth/data/auth_repository.dart';
import 'package:kise/features/auth/domain/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
}

@immutable
class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final String? redirectRoute;
  final AuthSuccessType? successType;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.redirectRoute,
    this.successType,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null,
        errorMessage = null,
        redirectRoute = null,
        successType = null;

  const AuthState.loading({
    this.user,
    this.redirectRoute,
    this.successType,
  })  : status = AuthStatus.loading,
        errorMessage = null;

  const AuthState.authenticated({
    required this.user,
    this.redirectRoute,
    this.successType,
  })  : status = AuthStatus.authenticated,
        errorMessage = null;

  const AuthState.unauthenticated({
    this.errorMessage,
    this.redirectRoute,
    this.successType,
  })  : status = AuthStatus.unauthenticated,
        user = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    String? redirectRoute,
    AuthSuccessType? successType,
    bool clearError = false,
    bool clearUser = false,
    bool clearRedirect = false,
    bool clearSuccessType = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      redirectRoute:
          clearRedirect ? null : (redirectRoute ?? this.redirectRoute),
      successType:
          clearSuccessType ? null : (successType ?? this.successType),
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repository;

  @override
  Future<AuthState> build() async {
    _repository = ref.read(authRepositoryProvider);
    return _bootstrap();
  }

  Future<AuthState> _bootstrap() async {
    state = const AsyncLoading();

    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(AppStorageKeys.onboardingSeen) ?? false;

    final hasSession = await _repository.hasStoredSession();
    if (!hasSession) {
      final route = onboardingSeen ? AppRoutes.login : AppRoutes.onboarding;
      return AuthState.unauthenticated(redirectRoute: route);
    }

    try {
      final session = await _repository.restoreSession();
      if (session == null) {
        final route = onboardingSeen ? AppRoutes.login : AppRoutes.onboarding;
        return AuthState.unauthenticated(redirectRoute: route);
      }

      return AuthState.authenticated(
        user: session.user,
        redirectRoute: AppRoutes.home,
      );
    } on ApiException catch (error) {
      final route = onboardingSeen ? AppRoutes.login : AppRoutes.onboarding;
      return AuthState.unauthenticated(
        errorMessage: error.message,
        redirectRoute: route,
      );
    } catch (error) {
      final route = onboardingSeen ? AppRoutes.login : AppRoutes.onboarding;
      return AuthState.unauthenticated(
        errorMessage: error.toString(),
        redirectRoute: route,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AsyncData(
      AuthState.loading(
        user: state.value?.user,
        successType: null,
      ),
    );

    try {
      final session = await _repository.login(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppStorageKeys.authLoggedIn, true);

      state = AsyncData(
        AuthState.authenticated(
          user: session.user,
          redirectRoute: AppRoutes.success,
          successType: AuthSuccessType.signIn,
        ),
      );
    } on ApiException catch (error) {
      state = AsyncData(
        AuthState.unauthenticated(
          errorMessage: error.message,
          redirectRoute: AppRoutes.login,
          successType: null,
        ),
      );
      rethrow;
    } catch (error) {
      state = AsyncData(
        AuthState.unauthenticated(
          errorMessage: error.toString(),
          redirectRoute: AppRoutes.login,
          successType: null,
        ),
      );
      rethrow;
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = AsyncData(
      AuthState.loading(
        user: state.value?.user,
        successType: null,
      ),
    );

    try {
      final session = await _repository.register(request);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppStorageKeys.authLoggedIn, true);

      state = AsyncData(
        AuthState.authenticated(
          user: session.user,
          redirectRoute: AppRoutes.success,
          successType: AuthSuccessType.registration,
        ),
      );
    } on ApiException catch (error) {
      state = AsyncData(
        AuthState.unauthenticated(
          errorMessage: error.message,
          redirectRoute: AppRoutes.register,
          successType: null,
        ),
      );
      rethrow;
    } catch (error) {
      state = AsyncData(
        AuthState.unauthenticated(
          errorMessage: error.toString(),
          redirectRoute: AppRoutes.register,
          successType: null,
        ),
      );
      rethrow;
    }
  }

  Future<void> logout({bool navigateToLogin = true}) async {
    state = const AsyncData(AuthState.loading());

    try {
      await _repository.logout();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppStorageKeys.authLoggedIn, false);

      state = AsyncData(
        AuthState.unauthenticated(
          redirectRoute: navigateToLogin ? AppRoutes.login : null,
        ),
      );
    }
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null || !current.isAuthenticated) {
      return;
    }

    try {
      final user = await _repository.fetchCurrentUser();
      state = AsyncData(
        current.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      state = AsyncData(
        current.copyWith(errorMessage: error.message),
      );
      rethrow;
    }
  }

  Future<void> onSessionExpired() async {
    await logout(navigateToLogin: true);
  }

  void clearRedirectRoute() {
    final current = state.value;
    if (current == null) {
      return;
    }

    state = AsyncData(
      current.copyWith(clearRedirect: true, clearSuccessType: true),
    );
  }

  void clearError() {
    final current = state.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(clearError: true));
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authStateProvider = Provider<AuthState?>((ref) {
  return ref.watch(authNotifierProvider).value;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider)?.isAuthenticated ?? false;
});