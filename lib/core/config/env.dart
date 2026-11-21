/// Alamat API. Ganti lewat: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
/// 10.0.2.2 = localhost komputer dari emulator Android.
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
  static const deviceName = String.fromEnvironment('DEVICE_NAME', defaultValue: 'sapore-kasir-android');
}
