import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class BluetoothPrintService {
  static final BluetoothPrintService _instance =
      BluetoothPrintService._internal();
  factory BluetoothPrintService() => _instance;
  BluetoothPrintService._internal();

  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isPrinting = false;

  // Getter for connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;

  // Start scanning for Bluetooth devices
  Stream<List<BluetoothDevice>> startScan() {
    if (_isScanning) {
      debugPrint('🔄 Already scanning, stopping previous scan...');
    }

    _isScanning = true;
    debugPrint('🔍 Starting Bluetooth SPP device scan...');

    // For SPP devices, we need to scan for new devices AND show bonded devices
    // Return a stream that provides scan results
    return Stream.periodic(const Duration(milliseconds: 1000), (_) async {
      try {
        // Get bonded (paired) devices
        final bondedDevices =
            await BlueThermalPrinter.instance.getBondedDevices();
        debugPrint('📱 Found ${bondedDevices.length} bonded SPP devices');

        // Filter for likely thermal printers
        final filteredDevices = bondedDevices.where((device) {
          final isLikelyPrinter = isLikelyThermalPrinter(device);
          debugPrint(
              '🔍 Device: ${device.name ?? "Unknown"} (${device.address}) - Likely printer: $isLikelyPrinter');
          return isLikelyPrinter;
        }).toList();

        debugPrint(
            '✅ Filtered to ${filteredDevices.length} likely thermal printers');
        return filteredDevices;
      } catch (e) {
        debugPrint('💥 Error during SPP device scan: $e');
        return <BluetoothDevice>[];
      }
    }).asyncMap((future) => future).take(15); // Stream for 15 seconds
  }

  // Stop scanning
  void stopScan() {
    debugPrint('🛑 Stopping Bluetooth device scan...');
    _isScanning = false;
    debugPrint('✅ Scan stopped');
  }

  // Connect to a Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _isConnecting = true;
      debugPrint('=== STARTING SPP DEVICE CONNECTION ===');
      debugPrint(
          '🔌 Attempting to connect to: ${device.name} (${device.address})');
      debugPrint('📱 Device type: ${device.name}');
      debugPrint('🔑 Device address: ${device.address}');

      debugPrint('⏳ Connecting to SPP device...');
      final result = await BlueThermalPrinter.instance.connect(device);

      if (result == 'true' || result == true) {
        _connectedDevice = device;
        debugPrint('✅ Successfully connected to SPP device');
        debugPrint('=== SPP DEVICE CONNECTION COMPLETED ===');
        _isConnecting = false;
        return true;
      } else {
        debugPrint('❌ Failed to connect to SPP device: $result');
        _isConnecting = false;
        return false;
      }
    } catch (e) {
      debugPrint('💥 Connection failed with error: $e');
      _connectedDevice = null;
      _isConnecting = false;
      debugPrint('=== SPP DEVICE CONNECTION FAILED ===');
      return false;
    }
  }

  // Disconnect from current device
  Future<void> disconnect() async {
    debugPrint('=== STARTING SPP DEVICE DISCONNECTION ===');
    if (_connectedDevice != null) {
      debugPrint(
          '🔌 Disconnecting from: ${_connectedDevice!.name} (${_connectedDevice!.address})');
      await BlueThermalPrinter.instance.disconnect();
      debugPrint('✅ Device disconnected');
      _connectedDevice = null;
    } else {
      debugPrint('ℹ️ No device connected to disconnect');
    }
    debugPrint('=== SPP DEVICE DISCONNECTION COMPLETED ===');
  }

  // Check if printer is ready to receive data
  Future<bool> isPrinterReady() async {
    if (_connectedDevice == null) {
      debugPrint('❌ Printer not ready: No device connected');
      return false;
    }

    try {
      // Check if device is still connected
      final isConnected = await BlueThermalPrinter.instance.isConnected;
      debugPrint('🔌 SPP connection status: $isConnected');

      if (!isConnected!) {
        debugPrint('❌ Printer not ready: Device disconnected');
        return false;
      }

      debugPrint('✅ SPP printer is ready for data transmission');
      return true;
    } catch (e) {
      debugPrint('💥 Error checking printer readiness: $e');
      return false;
    }
  }

  // Print receipt using ESC/POS commands
  Future<bool> printReceipt({
    required String title,
    required String patientName,
    required String doctorName,
    required String tokenNumber,
    required String dateTime,
    String? additionalInfo,
  }) async {
    if (_connectedDevice == null) {
      debugPrint('❌ Print failed: No device connected');
      return false;
    }

    try {
      _isPrinting = true;
      debugPrint('=== STARTING RECEIPT PRINT ===');
      debugPrint(
          'Printer: ${_connectedDevice!.name} (${_connectedDevice!.address})');
      debugPrint('Title: $title');
      debugPrint('Patient: $patientName');
      debugPrint('Doctor: $doctorName');
      debugPrint('Token: $tokenNumber');
      debugPrint('DateTime: $dateTime');
      debugPrint('Additional Info: ${additionalInfo ?? "None"}');

      // Check if printer is ready before starting
      if (!await isPrinterReady()) {
        debugPrint('❌ Print failed: Printer not ready');
        _isPrinting = false;
        return false;
      }

      debugPrint('✅ Printer is ready, generating ESC/POS data...');

      // Create receipt using esc_pos_utils
      final profile = await CapabilityProfile.load();
      debugPrint('📋 Loaded printer capability profile: ${profile.name}');

      final generator = Generator(PaperSize.mm80, profile);
      debugPrint('🖨️ Created generator for 80mm paper');

      List<int> bytes = [];

      // Header
      debugPrint('📝 Generating header...');
      bytes += generator.text(title,
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2));
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('=' * 32,
          styles: const PosStyles(align: PosAlign.center));
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));

      // Token number (highlighted)
      debugPrint('🔢 Generating token number section...');
      bytes += generator.text('TOKEN NUMBER',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text(tokenNumber,
          styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size3,
              width: PosTextSize.size3,
              bold: true));
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));

      // Patient details
      debugPrint('👤 Generating patient details...');
      bytes += generator.text('PATIENT:', styles: const PosStyles(bold: true));
      bytes += generator.text(patientName);
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));

      // Doctor details
      debugPrint('👨‍⚕️ Generating doctor details...');
      bytes += generator.text('DOCTOR:', styles: const PosStyles(bold: true));
      bytes += generator.text(doctorName);
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));

      // Date and time
      debugPrint('📅 Generating date/time section...');
      bytes +=
          generator.text('DATE & TIME:', styles: const PosStyles(bold: true));
      bytes += generator.text(dateTime);
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));

      // Additional info if provided
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        debugPrint('ℹ️ Generating additional info section...');
        bytes += generator.text('ADDITIONAL INFO:',
            styles: const PosStyles(bold: true));
        bytes += generator.text(additionalInfo);
        bytes +=
            generator.text('', styles: const PosStyles(align: PosAlign.center));
      }

      // Footer
      debugPrint('🏁 Generating footer...');
      bytes += generator.text('=' * 32,
          styles: const PosStyles(align: PosAlign.center));
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Thank you for visiting!',
          styles: const PosStyles(align: PosAlign.center));
      bytes +=
          generator.text('', styles: const PosStyles(align: PosAlign.center));

      // Cut paper
      debugPrint('✂️ Adding paper cut command...');
      bytes += generator.cut();

      debugPrint('📊 Generated ${bytes.length} bytes of ESC/POS data');
      debugPrint(
          '🔍 First 50 bytes: ${bytes.take(50).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');

      // Print the receipt using the existing printData method
      debugPrint('🚀 Starting print transmission...');
      final success = await printData(Uint8List.fromList(bytes));

      if (success) {
        debugPrint('✅ Receipt print completed successfully!');
      } else {
        debugPrint('❌ Receipt print failed!');
      }

      _isPrinting = false;
      debugPrint('=== RECEIPT PRINT COMPLETED ===');
      return success;
    } catch (e) {
      debugPrint('💥 Print failed with error: $e');
      debugPrint('=== RECEIPT PRINT FAILED ===');
      _isPrinting = false;
      return false;
    }
  }

  // Print data to the connected device
  Future<bool> printData(Uint8List data) async {
    if (_connectedDevice == null) {
      debugPrint('❌ Print failed: No device connected');
      return false;
    }

    try {
      _isPrinting = true;
      debugPrint('=== STARTING SPP DATA PRINT ===');
      debugPrint('📱 Data size: ${data.length} bytes');
      debugPrint(
          '🖨️ Target printer: ${_connectedDevice!.name} (${_connectedDevice!.address})');

      // Check if printer is ready before starting
      if (!await isPrinterReady()) {
        debugPrint('❌ Print failed: Printer not ready');
        _isPrinting = false;
        return false;
      }

      // Convert Uint8List to List<int> for printing
      List<int> bytes = data.toList();
      debugPrint(
          '📊 Converting data: ${bytes.length} bytes ready for transmission');

      // For SPP thermal printers, we can send larger chunks
      const int chunkSize = 512; // SPP can handle larger chunks
      int totalChunks = (bytes.length / chunkSize).ceil();
      int successfulChunks = 0;

      debugPrint(
          '📦 Will send data in $totalChunks chunks of $chunkSize bytes each');

      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);
        int currentChunk = (i ~/ chunkSize) + 1;

        debugPrint(
            '📤 Sending chunk $currentChunk/$totalChunks (${chunk.length} bytes)...');

        try {
          // Check printer readiness before each chunk
          if (!await isPrinterReady()) {
            debugPrint(
                '❌ Printer became unavailable during printing at chunk $currentChunk');
            _isPrinting = false;
            return false;
          }

          // Log chunk data for debugging
          debugPrint(
              '🔍 Chunk $currentChunk data (first 20 bytes): ${chunk.take(20).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');

          // Send data via SPP
          debugPrint('✍️ Writing chunk via SPP...');
          await BlueThermalPrinter.instance
              .writeBytes(Uint8List.fromList(chunk));
          debugPrint('✅ Chunk $currentChunk written successfully via SPP');

          successfulChunks++;
          debugPrint(
              '📈 Progress: $successfulChunks/$totalChunks chunks sent (${(successfulChunks / totalChunks * 100).toStringAsFixed(1)}%)');

          // Shorter delay for SPP (more reliable than BLE)
          debugPrint('⏳ Waiting 20ms before next chunk...');
          await Future.delayed(const Duration(milliseconds: 20));
        } catch (e) {
          debugPrint('💥 Failed to write chunk $currentChunk: $e');
          debugPrint(
              '📊 Successfully sent $successfulChunks/$totalChunks chunks before failure');
          _isPrinting = false;
          return false;
        }
      }

      // Wait for SPP printer to process all data
      debugPrint('⏳ Waiting 500ms for SPP printer to process all data...');
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('🎉 SPP print operation completed successfully!');
      debugPrint(
          '📊 Final stats: Sent $successfulChunks/$totalChunks chunks (${(successfulChunks / totalChunks * 100).toStringAsFixed(1)}% success rate)');
      debugPrint('=== SPP DATA PRINT COMPLETED ===');

      _isPrinting = false;
      return successfulChunks == totalChunks;
    } catch (e) {
      debugPrint('💥 Print failed with error: $e');
      debugPrint('=== SPP DATA PRINT FAILED ===');
      _isPrinting = false;
      return false;
    }
  }

  // Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      debugPrint('🔍 Checking Bluetooth availability...');
      final isEnabled = await BlueThermalPrinter.instance.isOn;
      debugPrint('📱 Bluetooth enabled: $isEnabled');
      return isEnabled ?? false;
    } catch (e) {
      debugPrint('❌ Error checking Bluetooth availability: $e');
      return false;
    }
  }

  // Get all bonded (paired) devices for manual inspection
  Future<List<BluetoothDevice>> getAllBondedDevices() async {
    try {
      debugPrint('🔍 Getting all bonded SPP devices...');
      final devices = await BlueThermalPrinter.instance.getBondedDevices();
      debugPrint('📱 Found ${devices.length} total bonded devices');

      for (final device in devices) {
        final isLikelyPrinter = isLikelyThermalPrinter(device);
        debugPrint(
            '📱 Bonded device: ${device.name ?? "Unknown"} (${device.address}) - Likely printer: $isLikelyPrinter');
      }

      return devices;
    } catch (e) {
      debugPrint('💥 Error getting bonded devices: $e');
      return <BluetoothDevice>[];
    }
  }

  // Open Bluetooth settings to help users pair new devices
  Future<void> openBluetoothSettings() async {
    try {
      debugPrint('🔧 Opening Bluetooth settings...');
      await BlueThermalPrinter.instance.openSettings;
      debugPrint('✅ Bluetooth settings opened');
    } catch (e) {
      debugPrint('❌ Error opening Bluetooth settings: $e');
    }
  }

  // Request Bluetooth permissions (Android)
  Future<void> requestPermissions() async {
    try {
      debugPrint('🔐 Requesting Bluetooth permissions...');
      // blue_thermal_printer handles permissions automatically
      debugPrint('✅ Bluetooth permissions handled automatically');
    } catch (e) {
      debugPrint('❌ Permission request failed: $e');
    }
  }

  // Reset connection state (useful for testing or when switching contexts)
  void resetConnectionState() {
    debugPrint('=== RESETTING SPP CONNECTION STATE ===');
    debugPrint('🔄 Before reset:');
    debugPrint('   - Connected device: ${_connectedDevice?.name ?? "None"}');
    debugPrint('   - Device address: ${_connectedDevice?.address ?? "None"}');
    debugPrint('   - Is connecting: $_isConnecting');
    debugPrint('   - Is printing: $_isPrinting');

    _connectedDevice = null;
    _isConnecting = false;
    _isPrinting = false;

    debugPrint('✅ After reset:');
    debugPrint('   - Connected device: ${_connectedDevice?.name ?? "None"}');
    debugPrint('   - Device address: ${_connectedDevice?.address ?? "None"}');
    debugPrint('   - Is connecting: $_isConnecting');
    debugPrint('   - Is printing: $_isPrinting');
    debugPrint('=== SPP CONNECTION STATE RESET COMPLETED ===');
  }

  // Force clear all state (nuclear option)
  void forceClearAllState() {
    debugPrint('=== FORCE CLEARING ALL SPP STATE ===');
    debugPrint('🧹 Clearing all Bluetooth service state...');

    _connectedDevice = null;
    _isConnecting = false;
    _isPrinting = false;
    _isScanning = false;

    debugPrint('✅ All state cleared');
    debugPrint('=== FORCE CLEAR COMPLETED ===');
  }

  // Check if we have a valid, active connection
  bool get hasValidConnection {
    debugPrint('🔍 Checking for valid SPP connection...');
    debugPrint('   - Connected device: ${_connectedDevice?.name ?? "None"}');
    debugPrint('   - Device address: ${_connectedDevice?.address ?? "None"}');

    if (_connectedDevice == null) {
      debugPrint('❌ No connected device');
      return false;
    }

    // Check if we have a device and SPP connection is active
    final result = _connectedDevice != null;
    debugPrint('✅ Valid SPP connection: $result');
    return result;
  }

  // Get display name for a device
  String getDeviceDisplayName(BluetoothDevice device) {
    final name = device.name ?? 'Unknown Device';
    debugPrint('📱 Getting display name for SPP device: $name');
    return name;
  }

  // Check if a device is likely a thermal printer based on its name
  bool _isLikelyThermalPrinter(String deviceName) {
    debugPrint(
        '🔍 Checking if SPP device is likely thermal printer: "$deviceName"');

    // If device name is empty, we can't determine from name alone
    if (deviceName.isEmpty) {
      debugPrint('❌ Device name is empty, cannot determine printer type');
      return false;
    }

    final name = deviceName.toLowerCase();
    debugPrint('🔍 Normalized SPP device name: "$name"');

    // Common thermal printer keywords for SPP devices
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
      'melk',
      'oa21w',
      'bluetooth',
      'bt',
      'serial',
      'usb',
      'com',
      'port',
      'spp', // SPP specific
      'classic', // Classic Bluetooth
      'hc', // HC-05, HC-06 modules
      'jdy', // JDY modules
      'ble', // Some modules show BLE but support SPP
    ];

    // Check if device name contains any printer keywords
    for (final keyword in printerKeywords) {
      if (name.contains(keyword)) {
        debugPrint('✅ SPP device matches printer keyword: "$keyword"');
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
      RegExp(r'hc-\d+', caseSensitive: false), // HC-05, HC-06 patterns
      RegExp(r'jdy-\d+', caseSensitive: false), // JDY module patterns
    ];

    for (final pattern in printerPatterns) {
      if (pattern.hasMatch(name)) {
        debugPrint('✅ SPP device matches printer pattern: ${pattern.pattern}');
        return true;
      }
    }

    debugPrint('❌ SPP device does not appear to be a thermal printer');
    return false;
  }

  // Check if a device is likely a thermal printer (public method)
  bool isLikelyThermalPrinter(BluetoothDevice device) {
    debugPrint(
        '🔍 Checking if SPP device is likely thermal printer: ${device.name ?? "Unknown"}');
    return _isLikelyThermalPrinter(device.name ?? '');
  }

  // Check if currently connecting to a device
  bool get isConnecting => _isConnecting;

  // Check if currently printing
  bool get isPrinting => _isPrinting;

  // Set printing state
  void setPrintingState(bool printing) {
    debugPrint('🔄 Setting printing state: $_isPrinting -> $printing');
    _isPrinting = printing;
  }
}
