import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_repository.dart';

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage storage = const FlutterSecureStorage()])
    : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> clear() async {
    await _storage.delete(key: 'account_access_token');
    await _storage.delete(key: 'account_refresh_token');
    await _storage.delete(key: 'account_access_token_expires_at');
  }
}
