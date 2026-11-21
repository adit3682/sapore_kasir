import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../orders/orders_repository.dart';
import '../orders/receipt_text.dart';
import 'escpos.dart';
import 'thermal_printer.dart';

class PrinterSelection {
  const PrinterSelection({this.mac, this.name});
  final String? mac;
  final String? name;
  bool get isSet => mac != null;
}

/// Printer terpilih (disimpan di perangkat) + aksi cetak. Semua aksi mengembalikan
/// pesan error (String) atau null bila berhasil.
class PrinterController extends Notifier<PrinterSelection> {
  static const _macKey = 'printer_mac_v1';
  static const _nameKey = 'printer_name_v1';

  @override
  PrinterSelection build() {
    _load();
    return const PrinterSelection();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final mac = p.getString(_macKey);
    if (mac != null && !state.isSet) state = PrinterSelection(mac: mac, name: p.getString(_nameKey));
  }

  Future<void> select(PrinterDevice d) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_macKey, d.mac);
    await p.setString(_nameKey, d.name);
    await ref.read(thermalPrinterProvider).disconnect(); // sambungan lama tidak berlaku lagi
    state = PrinterSelection(mac: d.mac, name: d.name);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_macKey);
    await p.remove(_nameKey);
    state = const PrinterSelection();
  }

  Future<String?> printBytes(List<int> bytes) async {
    final sel = state;
    if (!sel.isSet) return 'Belum ada printer dipilih.';
    final printer = ref.read(thermalPrinterProvider);
    try {
      if (!await printer.ensurePermission()) return 'Izin Bluetooth ditolak. Aktifkan di pengaturan HP.';
      if (!await printer.isConnected()) {
        if (!await printer.connect(sel.mac!)) {
          return 'Tidak bisa terhubung ke ${sel.name}. Pastikan printer menyala dan sudah dipasangkan di pengaturan Bluetooth HP.';
        }
      }
      if (!await printer.write(bytes)) {
        await printer.disconnect(); // paksa sambung ulang pada cetak berikutnya
        return 'Gagal mengirim data ke printer.';
      }
      return null;
    } catch (e) {
      return 'Printer bermasalah: $e';
    }
  }

  Future<String?> printReceipt(Map<String, dynamic> receipt) => printBytes(buildEscPos(formatReceipt(receipt)));

  /// Ambil struk dari server lalu cetak (dipakai layar "Pembayaran berhasil").
  Future<String?> printOrderReceipt(String orderUuid) async {
    try {
      final data = await ref.read(ordersRepositoryProvider).receipt(orderUuid);
      return printReceipt(data);
    } catch (e) {
      return '$e';
    }
  }

  Future<String?> printTest() => printBytes(buildEscPos(
        ['SAPORE Kasir', '-' * 32, 'Tes printer berhasil', 'Teks ini harus rapi dan', 'tidak terpotong di tepi kertas.', '-' * 32].join('\n'),
      ));
}

final printerControllerProvider = NotifierProvider<PrinterController, PrinterSelection>(PrinterController.new);

final pairedPrintersProvider = FutureProvider.autoDispose<List<PrinterDevice>>((ref) async {
  final p = ref.watch(thermalPrinterProvider);
  if (!await p.ensurePermission()) throw Exception('Izin Bluetooth ditolak. Aktifkan di pengaturan HP.');
  return p.pairedDevices();
});
