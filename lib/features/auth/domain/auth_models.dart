enum AuthSuccessType {
  registration,
  signIn,
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }
}

class AuthUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? username;
  final String university;
  final String department;
  final String currency;
  final String preferredLanguage;
  final String themeMode;

  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.username,
    required this.university,
    required this.department,
    required this.currency,
    required this.preferredLanguage,
    this.themeMode = 'system',
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      username: json['username'] as String?,
      university: json['university'] as String? ?? '',
      department: json['department'] as String? ?? '',
      currency: json['currency'] as String? ?? 'ETB',
      preferredLanguage: json['preferredLanguage'] as String? ?? 'English',
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'username': username,
      'university': university,
      'department': department,
      'currency': currency,
      'preferredLanguage': preferredLanguage,
      'themeMode': themeMode,
    };
  }
}

class AuthSession {
  final AuthUser user;
  final AuthTokens? tokens;

  const AuthSession({
    required this.user,
    this.tokens,
  });
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String? username;
  final String? phone;
  final String email;
  final String password;
  final String confirmPassword;
  final String university;
  final String department;
  final String preferredLanguage;
  final String currency;
  final bool termsAccepted;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    this.username,
    this.phone,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.university,
    required this.department,
    required this.preferredLanguage,
    required this.currency,
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'phone': phone,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'university': university,
      'department': department,
      'preferredLanguage': preferredLanguage,
      'currency': currency,
      'termsAccepted': termsAccepted,
    };
  }
}