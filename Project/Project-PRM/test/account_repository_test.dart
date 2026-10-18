import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_prm/features/account/data/account_repository.dart';

void main() {
  late _FakeAdapter adapter;
  late _MemoryTokenStore tokenStore;
  late AccountRepository repository;

  setUp(() {
    adapter = _FakeAdapter();
    tokenStore = _MemoryTokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'))
      ..httpClientAdapter = adapter;
    repository = AccountRepository(dio, tokenStore);
  });

  test('signs in and fetches the authenticated profile', () async {
    await repository.signIn(email: 'user@example.com', password: 'secret');
    final user = await repository.fetchCurrentUser();

    expect(user.fullName, 'Taylor User');
    expect(user.email, 'user@example.com');
    expect(adapter.requests.map((request) => request.path), [
      '/auth/login',
      '/user/me',
    ]);
    expect(adapter.requests[0].data, {
      'email': 'user@example.com',
      'password': 'secret',
    });
    expect(adapter.requests[1].headers['Authorization'], 'Bearer access-token');
    expect(await repository.hasSession(), isTrue);
  });

  test(
    'refreshes an expired access token before fetching the profile',
    () async {
      await tokenStore.write('account_access_token', 'expired-token');
      await tokenStore.write('account_refresh_token', 'refresh-token');
      await tokenStore.write(
        'account_access_token_expires_at',
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      );

      final user = await repository.fetchCurrentUser();

      expect(user.id, 'user-1');
      expect(adapter.requests.map((request) => request.path), [
        '/auth/refresh',
        '/user/me',
      ]);
      expect(
        adapter.requests.first.headers['X-Refresh-Token'],
        'refresh-token',
      );
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer refreshed-token',
      );
    },
  );
}

class _MemoryTokenStore implements TokenStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> clear() async => values.clear();
}

class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = switch (options.path) {
      '/auth/login' => {
        'status': 'success',
        'data': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
      },
      '/auth/refresh' => {
        'status': 'success',
        'data': {'accessToken': 'refreshed-token'},
      },
      '/user/me' => {
        'status': 'success',
        'data': {
          'id': 'user-1',
          'email': 'user@example.com',
          'fullName': 'Taylor User',
          'phoneNumber': '555-0100',
          'profile': 'profile.png',
        },
      },
      _ => throw StateError('Unexpected request path: ${options.path}'),
    };

    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
