import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sapore_kasir/features/printing/escpos.dart';
import 'package:sapore_kasir/features/printing/printer_controller.dart';
import 'package:sapore_kasir/features/printing/thermal_printer.dart';

class _FakePrinter implements ThermalPrinter {
  _FakePrinter({this.canConnect = true, this.canWrite = true});
  final bool canConnect, canWrite;
  bool connected = false;
  List<int>? written;
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Future<List<PrinterDevice>> pairedDevices() async => const [PrinterDevice('RPP02N', 'AA:BB')];
  @override
  Future<bool> isConnected() async => connected;
  @override
  Future<bool> connect(String mac) async => connected = canConnect;
  @override
  Future<bool> write(List<int> bytes) async {
    written = bytes;
    return canWrite;
  }
  @override
  Future<void> disconnect() async => connected = false;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ESC/POS: reset di awal, potong di akhir, hanya ASCII', () {
    final b = buildEscPos('SAPORÉ\nItem 2 × 5.000\nTOTAL 10.000');
    expect(b.take(2), [0x1B, 0x40]);
    expect(b.skip(b.length - 4), [0x1D, 0x56, 0x42, 0x00]);
    final controlFree = b.where((x) => x > 126).toList();
    expect(controlFree, isEmpty);
    expect(String.fromCharCodes(b.where((x) => x >= 32 && x <= 126)), contains('SAPORE'));
  });

  test('ESC/POS: baris TOTAL dibungkus perintah tebal', () {
    final b = buildEscPos('TOTAL 1', cut: false);
    expect(b.sublist(2, 5), [0x1B, 0x45, 0x01]);
    expect(b.contains(0x00), isTrue);
  });

  ProviderContainer container(_FakePrinter p) =>
      ProviderContainer(overrides: [thermalPrinterProvider.overrideWithValue(p)]);

  test('cetak tanpa printer terpilih -> pesan', () async {
    final c = container(_FakePrinter());
    addTearDown(c.dispose);
    expect(await c.read(printerControllerProvider.notifier).printBytes([1]), contains('Belum ada printer'));
  });

  test('cetak sukses: menyambung lalu menulis', () async {
    final fake = _FakePrinter();
    final c = container(fake);
    addTearDown(c.dispose);
    final n = c.read(printerControllerProvider.notifier);
    await n.select(const PrinterDevice('RPP02N', 'AA:BB'));
    expect(await n.printBytes([1, 2]), isNull);
    expect(fake.written, [1, 2]);
  });

  test('gagal sambung / gagal tulis -> pesan error', () async {
    final c1 = container(_FakePrinter(canConnect: false));
    addTearDown(c1.dispose);
    final n1 = c1.read(printerControllerProvider.notifier);
    await n1.select(const PrinterDevice('X', 'AA'));
    expect(await n1.printBytes([1]), contains('Tidak bisa terhubung'));

    final c2 = container(_FakePrinter(canWrite: false));
    addTearDown(c2.dispose);
    final n2 = c2.read(printerControllerProvider.notifier);
    await n2.select(const PrinterDevice('X', 'AA'));
    expect(await n2.printBytes([1]), contains('Gagal mengirim'));
  });
}
