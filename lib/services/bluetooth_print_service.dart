import 'dart:async';
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
      // Show only devices with names, but improve detection for valid printers
      final allDevices = results.map((result) => result.device).toList();
      devices =
          allDevices.where((device) => device.platformName.isNotEmpty).toList();

      debugPrint(
          'Bluetooth service: Found ${allDevices.length} total devices, ${devices.length} with names');

      for (var device in devices) {
        final isLikelyPrinter = _isLikelyThermalPrinter(device.platformName);
        debugPrint(
            'Bluetooth service: Device: ${device.platformName} (${device.remoteId}) - Likely printer: $isLikelyPrinter');
      }
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return devices;
    }).take(30); // Stream for 15 seconds
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
      debugPrint(
          'Bluetooth service: Attempting to connect to ${device.platformName} (${device.remoteId})');

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      debugPrint('Bluetooth service: Successfully connected to device');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      debugPrint('Bluetooth service: Discovered ${services.length} services');

      // Look for the write characteristic (common for thermal printers)
      _writeCharacteristic = null;
      for (BluetoothService service in services) {
        debugPrint('Bluetooth service: Checking service ${service.uuid}');
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          debugPrint(
              'Bluetooth service: Characteristic ${characteristic.uuid} - write: ${characteristic.properties.write}, writeWithoutResponse: ${characteristic.properties.writeWithoutResponse}');

          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            debugPrint(
                'Bluetooth service: Found writable characteristic: ${characteristic.uuid}');
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        debugPrint(
            'Bluetooth service: No writable characteristic found - this device may not be a thermal printer');
        throw Exception(
            'No writable characteristic found - this device may not be a thermal printer');
      }

      _isConnecting = false;
      debugPrint(
          'Bluetooth service: Connection successful with writable characteristic');
      return true;
    } catch (e) {
      debugPrint('Bluetooth service: Connection failed: $e');
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

  // Check if printer is ready to receive data
  Future<bool> isPrinterReady() async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      return false;
    }

    try {
      // Check if device is still connected
      final isConnected = await _connectedDevice!.isConnected;
      if (!isConnected) {
        debugPrint('Printer not ready: Device disconnected');
        return false;
      }

      // Check if characteristic is still valid
      if (_writeCharacteristic == null) {
        debugPrint('Printer not ready: No writable characteristic');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking printer readiness: $e');
      return false;
    }
  }

  // Print data to the connected device
  Future<bool> printData(Uint8List data) async {
    if (_connectedDevice == null) {
      debugPrint('Print failed: No device connected');
      return false;
    }

    try {
      _isPrinting = true;
      debugPrint('Starting print operation...');

      // Check if printer is ready before starting
      if (!await isPrinterReady()) {
        debugPrint('Print failed: Printer not ready');
        _isPrinting = false;
        return false;
      }

      if (_writeCharacteristic == null) {
        debugPrint('Print failed: No writable characteristic found');
        _isPrinting = false;
        return false;
      }

      // Convert Uint8List to List<int> for printing
      List<int> bytes = data.toList();
      debugPrint('Printing ${bytes.length} bytes of data');

      // For thermal printers, use smaller chunk size to prevent buffer overflow
      // Most thermal printers work best with smaller chunks
      const int chunkSize =
          100; // Reduced from 200 for better thermal printer compatibility
      int totalChunks = (bytes.length / chunkSize).ceil();
      int successfulChunks = 0;

      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);
        int currentChunk = (i ~/ chunkSize) + 1;

        try {
          // Check printer readiness before each chunk
          if (!await isPrinterReady()) {
            debugPrint(
                'Printer became unavailable during printing at chunk $currentChunk');
            _isPrinting = false;
            return false;
          }

          if (_writeCharacteristic!.properties.write) {
            await _writeCharacteristic!.write(chunk);
            debugPrint('Chunk $currentChunk/$totalChunks written successfully');
          } else if (_writeCharacteristic!.properties.writeWithoutResponse) {
            await _writeCharacteristic!.write(chunk, withoutResponse: true);
            debugPrint(
                'Chunk $currentChunk/$totalChunks written without response');
          } else {
            throw Exception(
                'Characteristic supports neither write nor writeWithoutResponse');
          }

          successfulChunks++;

          // Longer delay between chunks for thermal printers to prevent buffer overflow
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          debugPrint('Failed to write chunk $currentChunk: $e');
          _isPrinting = false;
          return false;
        }
      }

      // Wait longer for thermal printers to process all data
      await Future.delayed(const Duration(milliseconds: 1000));

      debugPrint(
          'Print operation completed successfully. Sent $successfulChunks/$totalChunks chunks');
      _isPrinting = false;
      return successfulChunks == totalChunks;
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
        'Bluetooth service: hasValidConnection will now return: $hasValidConnection');
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
    return device.platformName;
  }

  // Check if a device is likely a thermal printer based on its name
  bool _isLikelyThermalPrinter(String deviceName) {
    // If device name is empty, we can't determine from name alone
    // but we'll still allow it to be checked for characteristics
    if (deviceName.isEmpty) return false;

    final name = deviceName.toLowerCase();

    // Common thermal printer keywords
    final printerKeywords = [
      'printer',
      'thermal',
      'pos',
      'receipt',
      'esc',
      'star',
      'citizen',
      'epson',
      'brother',
      'zjiang',
      'gainscha',
      'bixolon',
      'tmt',
      'citizen',
      'dymo',
      'label',
      'tag',
      'melk', // Based on the device found in your logs
      'oa21w', // Based on the device found in your logs
      'bluetooth', // Some printers just show "Bluetooth"
      'bt', // Abbreviation for Bluetooth
      'serial', // Serial port printers
      'usb', // USB printers that also support Bluetooth
      'com', // COM port printers
      'port' // Port printers
    ];

    // Check if device name contains any printer keywords
    for (final keyword in printerKeywords) {
      if (name.contains(keyword)) {
        return true;
      }
    }

    // Check for common thermal printer model patterns
    final printerPatterns = [
      RegExp(r'sr\d+', caseSensitive: false), // SR588, SR300, etc.
      RegExp(r'[a-z]+\d+', caseSensitive: false), // Generic model patterns
      RegExp(r'[a-z]{2,3}\d{2,4}',
          caseSensitive: false), // Common printer model patterns
      RegExp(r'printer\d*', caseSensitive: false), // Generic printer patterns
    ];

    for (final pattern in printerPatterns) {
      if (pattern.hasMatch(name)) {
        return true;
      }
    }

    return false;
  }

  // Check if a device is likely a thermal printer (public method)
  bool isLikelyThermalPrinter(BluetoothDevice device) {
    return _isLikelyThermalPrinter(device.platformName);
  }

  // Check if a device has the right characteristics for thermal printing
  Future<bool> hasThermalPrinterCharacteristics(BluetoothDevice device) async {
    try {
      debugPrint(
          'Bluetooth service: Checking characteristics for ${device.platformName.isNotEmpty ? device.platformName : "Unknown Device"}');

      // First check if we can connect
      await device.connect(timeout: const Duration(seconds: 5));

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      debugPrint('Bluetooth service: Found ${services.length} services');

      // Look for write characteristics
      bool hasWriteChar = false;
      for (BluetoothService service in services) {
        debugPrint('Bluetooth service: Checking service ${service.uuid}');
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          debugPrint(
              'Bluetooth service: Characteristic ${characteristic.uuid} - write: ${characteristic.properties.write}, writeWithoutResponse: ${characteristic.properties.writeWithoutResponse}');

          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            hasWriteChar = true;
            debugPrint(
                'Bluetooth service: Found writable characteristic in ${device.platformName.isNotEmpty ? device.platformName : "Unknown Device"}');
            break;
          }
        }
        if (hasWriteChar) break;
      }

      // Disconnect after checking
      await device.disconnect();

      return hasWriteChar;
    } catch (e) {
      debugPrint('Bluetooth service: Error checking characteristics: $e');
      return false;
    }
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
