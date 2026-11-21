import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, signedOut, mustChangePassword, signedIn }

class AuthState {
  const AuthState(this.status, [this.user]);
  final AuthStatus status;
  final AuthUser? user;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Token ditolak server -> kembali ke layar login.
    Future.microtask(() => ref.read(onUnauthorizedProvider.notifier).state =
        () => state = const AuthState(AuthStatus.signedOut));
    _restore();
    return const AuthState(AuthStatus.unknown);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  AuthState _from(AuthUser u) =>
      AuthState(u.mustChangePassword ? AuthStatus.mustChangePassword : AuthStatus.signedIn, u);

  Future<void> _restore() async {
    final u = await _repo.restore();
    state = u == null ? const AuthState(AuthStatus.signedOut) : _from(u);
  }

  /// Melempar ApiException agar layar bisa menampilkan pesannya.
  Future<void> login(String email, String password) async =>
      state = _from(await _repo.login(email, password));

  Future<void> changePassword(String current, String next) async =>
      state = _from(await _repo.changePassword(current, next));

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(AuthStatus.signedOut);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
