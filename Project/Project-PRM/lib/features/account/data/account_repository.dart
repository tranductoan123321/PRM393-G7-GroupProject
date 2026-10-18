import 'package:dio/dio.dart';

import '../models/account_user.dart';

abstract interface class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> clear();
}

class AccountRepository {
  AccountRepository(this._dio, this._tokenStore);

  static const _accessTokenKey = 'account_access_token';
  static const _refreshTokenKey = 'account_refresh_token';
  static const _accessTokenExpiresAtKey = 'account_access_token_expires_at';

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<bool> hasSession() async =>
      (await _tokenStore.read(_refreshTokenKey))?.isNotEmpty ?? false;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = _successData(response.data, 'Could not sign in.');
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('The sign-in response did not include tokens.');
    }

    await _storeTokens(accessToken, refreshToken);
  }

  Future<AccountUser> fetchCurrentUser() async {
    final accessToken = await _getValidAccessToken();
    try {
      return await _requestCurrentUser(accessToken);
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) rethrow;
      final refreshedToken = await _refreshAccessToken();
      try {
        return await _requestCurrentUser(refreshedToken);
      } on DioException catch (retryError) {
        if (retryError.response?.statusCode == 401) {
          await _tokenStore.clear();
        }
        rethrow;
      }
    }
  }

  Future<void> signOut() => _tokenStore.clear();

  Future<AccountUser> _requestCurrentUser(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/user/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final data = _successData(response.data, 'Could not load account details.');
    return AccountUser.fromJson(data);
  }

  Future<String> _getValidAccessToken() async {
    final accessToken = await _tokenStore.read(_accessTokenKey);
    final expiresAtRaw = await _tokenStore.read(_accessTokenExpiresAtKey);
    final expiresAt = expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt)) {
      return accessToken;
    }

    return _refreshAccessToken();
  }

  Future<String> _refreshAccessToken() async {
    final refreshToken = await _tokenStore.read(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenStore.clear();
      throw const FormatException('Your session has expired. Please sign in again.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(headers: {'X-Refresh-Token': refreshToken}),
      );
      final data = _successData(response.data, 'Your session has expired.');
      final accessToken = data['accessToken'];
      if (accessToken is! String || accessToken.isEmpty) {
        throw const FormatException('The refresh response did not include an access token.');
      }
      await _storeTokens(accessToken, refreshToken);
      return accessToken;
    } on DioException {
      await _tokenStore.clear();
      rethrow;
    } on FormatException {
      await _tokenStore.clear();
      rethrow;
    }
  }

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: 4, seconds: 30))
        .toIso8601String();
    await _tokenStore.write(_accessTokenKey, accessToken);
    await _tokenStore.write(_refreshTokenKey, refreshToken);
    await _tokenStore.write(_accessTokenExpiresAtKey, expiresAt);
  }

  Map<String, dynamic> _successData(
    Map<String, dynamic>? response,
    String fallbackMessage,
  ) {
    if (response == null || response['status'] != 'success') {
      final error = response?['error'];
      final message = error is Map ? error['message'] : null;
      throw FormatException(
        message is String && message.isNotEmpty ? message : fallbackMessage,
      );
    }

    final data = response['data'];
    if (data is! Map) throw FormatException(fallbackMessage);
    return Map<String, dynamic>.from(data);
  }
}
