import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterDevice {
  const PrinterDevice(this.name, this.mac);
  final String name;
  final String mac;
}

/// Pemisah antara UI dan plugin Bluetooth, supaya mudah diuji/diganti (mis. USB nanti).
abstract class ThermalPrinter {
  Future<bool> ensurePermission();
  Future<List<PrinterDevice>> pairedDevices();
  Future<bool> isConnected();
  Future<bool> connect(String mac);
  Future<bool> write(List<int> bytes);
  Future<void> disconnect();
}

class BluetoothThermalPrinter implements ThermalPrinter {
  @override
  Future<bool> ensurePermission() async {
    final res = await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    return res.values.every((s) => s.isGranted || s.isLimited);
  }

  @override
  Future<List<PrinterDevice>> pairedDevices() async {
    final list = await PrintBluetoothThermal.pairedBluetooths;
    return [for (final d in list) PrinterDevice(d.name, d.macAdress)];
  }

  @override
  Future<bool> isConnected() => PrintBluetoothThermal.connectionStatus;

  @override
  Future<bool> connect(String mac) => PrintBluetoothThermal.connect(macPrinterAddress: mac);

  @override
  Future<bool> write(List<int> bytes) => PrintBluetoothThermal.writeBytes(bytes);

  @override
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }
}

final thermalPrinterProvider = Provider<ThermalPrinter>((_) => BluetoothThermalPrinter());
