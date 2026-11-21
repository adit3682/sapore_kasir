import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  static const _key = 'auth_token';

  Future<String?> read() => _s.read(key: _key);
  Future<void> write(String token) => _s.write(key: _key, value: token);
  Future<void> clear() => _s.delete(key: _key);
}

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
