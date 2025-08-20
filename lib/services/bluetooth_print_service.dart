import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothPrintService {
  static final BluetoothPrintService _instance =
      BluetoothPrintService._internal();
  factory BluetoothPrintService() => _instance;
  BluetoothPrintService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isPrinting = false;

  // Getter for connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  // Start scanning for Bluetooth devices
  Stream<List<BluetoothDevice>> startScan() {
    if (_isScanning) {
      _scanSubscription?.cancel();
    }

    _isScanning = true;
    List<BluetoothDevice> devices = [];

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final realDevices = results.map((result) => result.device).toList();
      // Filter for potential thermal printers (common names)
      final filteredDevices = realDevices.where((device) {
        final name = device.platformName.toLowerCase();
        return name.contains('printer') ||
            name.contains('thermal') ||
            name.contains('pos') ||
            name.contains('receipt') ||
            name.contains('esc') ||
            name.contains('star') ||
            name.contains('citizen') ||
            name.contains('epson') ||
            name.contains('brother');
      }).toList();

      devices = filteredDevices;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return devices;
    }).take(20); // Stream for 10 seconds
  }

  // Stop scanning
  void stopScan() {
    _isScanning = false;
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
  }

  // Connect to a Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _isConnecting = true;

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Look for the write characteristic (common for thermal printers)
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        throw Exception('No writable characteristic found');
      }

      _isConnecting = false;
      return true;
    } catch (e) {
      // Using a logging framework instead of print for production code
      debugPrint('Failed to connect: $e');
      _connectedDevice = null;
      _writeCharacteristic = null;
      _isConnecting = false;
      return false;
    }
  }

  // Disconnect from current device
  Future<void> disconnect() async {
    debugPrint('Bluetooth service: disconnect() called');
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _writeCharacteristic = null;
    }
    debugPrint(
        'Bluetooth service: disconnect completed, _connectedDevice: $_connectedDevice');
  }

  // Print data to the connected device
  Future<bool> printData(Uint8List data) async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }

    try {
      _isPrinting = true;

      if (_writeCharacteristic == null) {
        throw Exception('No writable characteristic found');
      }

      // Convert Uint8List to List<int> for printing
      List<int> bytes = data.toList();

      // Split data into chunks if it's too large
      const int chunkSize = 512;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);

        await _writeCharacteristic!.write(chunk);

        // Small delay between chunks to prevent buffer overflow
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _isPrinting = false;
      return true;
    } catch (e) {
      debugPrint('Print failed: $e');
      _isPrinting = false;
      return false;
    }
  }

  // Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  // Request Bluetooth permissions (Android)
  Future<void> requestPermissions() async {
    try {
      await FlutterBluePlus.adapterState.first;
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  // Reset connection state (useful for testing or when switching contexts)
  void resetConnectionState() {
    debugPrint('Bluetooth service: resetConnectionState called');
    debugPrint(
        'Bluetooth service: Before reset - _connectedDevice: $_connectedDevice, _writeCharacteristic: $_writeCharacteristic');
    _connectedDevice = null;
    _writeCharacteristic = null;
    _isConnecting = false;
    _isPrinting = false;
    debugPrint(
        'Bluetooth service: After reset - _connectedDevice: $_connectedDevice, _writeCharacteristic: $_writeCharacteristic');
    debugPrint(
        'Bluetooth service: hasValidConnection will now return: ${hasValidConnection}');
  }

  // Force clear all state (nuclear option)
  void forceClearAllState() {
    debugPrint('Bluetooth service: forceClearAllState called');
    _connectedDevice = null;
    _writeCharacteristic = null;
    _isConnecting = false;
    _isPrinting = false;
    _isScanning = false;
    if (_scanSubscription != null) {
      _scanSubscription!.cancel();
      _scanSubscription = null;
    }
    debugPrint('Bluetooth service: All state cleared');
  }

  // Check if we have a valid, active connection
  bool get hasValidConnection {
    debugPrint('Bluetooth service: hasValidConnection called');
    debugPrint(
        'Bluetooth service: _connectedDevice: $_connectedDevice, _writeCharacteristic: $_writeCharacteristic');

    if (_connectedDevice == null) {
      debugPrint(
          'Bluetooth service: hasValidConnection returning false (no device)');
      return false;
    }

    // Check if we have both device and characteristic
    final result = _connectedDevice != null && _writeCharacteristic != null;
    debugPrint(
        'Bluetooth service: hasValidConnection returning $result (real device)');
    return result;
  }

  // Get display name for a device
  String getDeviceDisplayName(BluetoothDevice device) {
    return device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
  }

  // Check if currently connecting to a device
  bool get isConnecting => _isConnecting;

  // Check if currently printing
  bool get isPrinting => _isPrinting;

  // Set printing state
  void setPrintingState(bool printing) {
    _isPrinting = printing;
  }
}
