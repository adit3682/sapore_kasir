# SAPORÉ Kasir (Flutter)

App kasir untuk backend SAPORÉ (Laravel, API `/api/v1`).

## Setup
```bash
# dari folder ini: membuat folder android/ ios/ dll. (lib/ dan pubspec.yaml tidak ditimpa)
flutter create --org com.sapore --project-name sapore_kasir .
flutter pub get
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```
Backend: `php artisan serve --host=0.0.0.0`. Emulator Android memakai `10.0.2.2`;
HP fisik memakai IP LAN komputer.

Karena API development memakai http (bukan https), tambahkan di
`android/app/src/main/AndroidManifest.xml` pada tag `<application>`:
`android:usesCleartextTraffic="true"` dan izin `<uses-permission android:name="android.permission.INTERNET"/>`
(hanya untuk development; produksi wajib https).

## Struktur
- `core/` konfigurasi, Dio + interceptor token, penyimpanan token, tema SAPORÉ
- `features/auth` login, ganti password wajib, pemulihan sesi
- `features/catalog` model, repository, cache lokal, sinkron updated_since
- `features/pos` layar kasir + keranjang (Bayar menyusul di langkah 4)
- `features/orders` riwayat, detail, bayar order Open, retur, struk order dan struk retur
- `router.dart` go_router dengan redirect berdasarkan status auth

## Roadmap
3. (selesai) Katalog kategori/pencarian, cache lokal, keranjang
4. (selesai) Pembayaran 4 metode, kembalian tunai, antrean offline (uuid idempoten)
5. (selesai) Riwayat order, struk (teks 58/80 mm), void, retur Owner/Manager

## Printer thermal (Bluetooth classic)
Pasangkan printer di Pengaturan Bluetooth HP, lalu buka ikon printer di layar kasir, pilih printer, tekan **Cetak Tes**.
Lebar kertas (58/80 mm) mengikuti `receipt.paper` di config Laravel (`config/sapore.php`).

Tambahkan izin berikut di `android/app/src/main/AndroidManifest.xml` (di dalam `<manifest>`, sebelum `<application>`):
```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation"/>
```
Printer USB belum didukung (butuh plugin lain).
