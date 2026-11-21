import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokens);
  final Dio _dio;
  final TokenStorage _tokens;

  Future<AuthUser> login(String email, String password) async {
    try {
      final r = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': Env.deviceName,
      });
      await _tokens.write(r.data['token'] as String);
      return AuthUser.fromJson(r.data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Memulihkan sesi dari token tersimpan. null bila tidak ada/tidak valid.
  Future<AuthUser?> restore() async {
    if (await _tokens.read() == null) return null;
    try {
      final r = await _dio.get('/auth/me');
      return AuthUser.fromJson(r.data['user'] as Map<String, dynamic>);
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }

  Future<AuthUser> changePassword(String current, String next) async {
    try {
      final r = await _dio.post('/auth/change-password', data: {
        'current_password': current,
        'password': next,
        'password_confirmation': next,
      });
      return AuthUser.fromJson(r.data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {/* token lokal tetap dihapus */}
    await _tokens.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
