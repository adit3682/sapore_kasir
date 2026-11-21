import 'package:dio/dio.dart';

/// Kesalahan API yang sudah dirapikan untuk ditampilkan ke kasir.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.network = false});
  final String message;
  final int? statusCode;
  final String? code;
  final bool network; // tidak ada respons dari server (offline/timeout)

  bool get isPasswordChangeRequired => code == 'password_change_required';
  bool get isUnauthorized => statusCode == 401;

  /// Aman dikirim ulang nanti: jaringan putus, 5xx, 408, 429.
  bool get retryable =>
      network || (statusCode != null && (statusCode! >= 500 || statusCode == 408 || statusCode == 429));

  factory ApiException.from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        String? first;
        if (errors is Map && errors.isNotEmpty) {
          final v = errors.values.first;
          first = v is List && v.isNotEmpty ? '${v.first}' : '$v';
        }
        return ApiException(
          first ?? (data['message'] as String?) ?? 'Terjadi kesalahan.',
          statusCode: e.response?.statusCode,
          code: data['code'] as String?,
        );
      }
      if (e.response == null) {
        return ApiException('Tidak dapat terhubung ke server.', network: true);
      }
      final code = e.response!.statusCode;
      return ApiException('Server bermasalah ($code).', statusCode: code);
    }
    return ApiException('Terjadi kesalahan tak terduga.');
  }

  @override
  String toString() => message;
}
