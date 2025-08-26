import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import '../models/token.dart';
import '../models/doctor.dart';
import 'bluetooth_print_service.dart';

class PrintService {
  // Generate print data for a token (for manual printing or sharing)
  Future<Uint8List> generateTokenPrintData(Token token, Doctor doctor) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Initialize printer - essential for thermal printers
    bytes += generator.reset(); // Reset printer to default state

    // Top border
    bytes += generator.text('==============================',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          align: PosAlign.center,
        ));

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Date and time
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final monthName = monthNames[token.generatedAt.month - 1];
    final dateFormat =
        '$monthName ${token.generatedAt.day}, ${token.generatedAt.year}';
    final timeFormat =
        '${token.generatedAt.hour.toString().padLeft(2, '0')}:${token.generatedAt.minute.toString().padLeft(2, '0')}';

    bytes += generator.text('$dateFormat $timeFormat',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          align: PosAlign.center,
        ));

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Doctor name
    bytes += generator.text('DR ${doctor.name.toUpperCase()}',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          bold: true,
          align: PosAlign.center,
        ));

    // Patient name
    bytes += generator.text(token.patientName,
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
          align: PosAlign.center,
        ));

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Serial number
    bytes += generator.text('Serial No - ${token.tokenNumber}',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          bold: true,
          align: PosAlign.center,
        ));

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Instruction text
    bytes += generator.text('keep this till you are in clinic',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          align: PosAlign.center,
        ));

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Bottom border
    bytes += generator.text('==============================',
        styles: const PosStyles(
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          align: PosAlign.center,
        ));

    // Essential thermal printer commands
    bytes += generator.feed(2); // Feed paper 2 lines
    bytes +=
        generator.text(''); // Empty line to ensure print buffer is processed
    bytes += generator.cut(); // Cut paper (if supported)

    // Add final paper feed to ensure printing completes
    bytes += generator.feed(1);

    return Uint8List.fromList(bytes);
  }

  // Generate print data for multiple tokens
  Future<Uint8List> generateMultipleTokensPrintData(
      List<Token> tokens, Doctor doctor) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Initialize printer - essential for thermal printers
    bytes += generator.reset(); // Reset printer to default state

    // Print each token individually in the same format
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Top border
      bytes += generator.text('==============================',
          styles: const PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            align: PosAlign.center,
          ));

      bytes += generator.text('',
          styles: const PosStyles(height: PosTextSize.size1));

      // Date and time
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final monthName = monthNames[token.generatedAt.month - 1];
      final dateFormat =
          '$monthName ${token.generatedAt.day}, ${token.generatedAt.year}';
      final timeFormat =
          '${token.generatedAt.hour.toString().padLeft(2, '0')}:${token.generatedAt.minute.toString().padLeft(2, '0')}';

      bytes += generator.text('$dateFormat $timeFormat',
          styles: const PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            align: PosAlign.center,
          ));

      bytes += generator.text('',
          styles: const PosStyles(height: PosTextSize.size1));

      // Doctor name
      bytes += generator.text('DR ${doctor.name.toUpperCase()}',
          styles: const PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            bold: true,
            align: PosAlign.center,
          ));

      // Patient name
      bytes += generator.text(token.patientName,
          styles: const PosStyles(
            height: PosTextSize.size2,
            width: PosTextSize.size2,
            bold: true,
            align: PosAlign.center,
          ));

      bytes += generator.text('',
          styles: const PosStyles(height: PosTextSize.size1));

      // Serial number
      bytes += generator.text('Serial No - ${token.tokenNumber}',
          styles: const PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            bold: true,
            align: PosAlign.center,
          ));

      bytes += generator.text('',
          styles: const PosStyles(height: PosTextSize.size1));

      // Instruction
      bytes += generator.text('keep this till you are in clinic',
          styles: const PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            align: PosAlign.center,
          ));

      bytes += generator.text('',
          styles: const PosStyles(height: PosTextSize.size1));

      // Bottom border
      bytes += generator.text('==============================',
          styles: const PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            align: PosAlign.center,
          ));

      // Add spacing between tokens (except for the last one)
      if (i < tokens.length - 1) {
        bytes += generator.text('',
            styles: const PosStyles(height: PosTextSize.size2));
        bytes += generator.text('',
            styles: const PosStyles(height: PosTextSize.size2));
      }
    }

    // Essential thermal printer commands for multiple tokens
    bytes += generator.feed(2); // Feed paper 2 lines
    bytes +=
        generator.text(''); // Empty line to ensure print buffer is processed
    bytes += generator.cut(); // Cut paper after all tokens

    // Add final paper feed to ensure printing completes
    bytes += generator.feed(1);

    return Uint8List.fromList(bytes);
  }

  // Print a single token via Bluetooth
  Future<bool> printTokenViaBluetooth(Token token, Doctor doctor) async {
    try {
      debugPrint('=== STARTING BLUETOOTH TOKEN PRINT ===');
      debugPrint('🔢 Token: ${token.tokenNumber}');
      debugPrint('👤 Patient: ${token.patientName}');
      debugPrint('👨‍⚕️ Doctor: ${doctor.name}');
      debugPrint('📅 Generated: ${token.generatedAt}');

      final printData = await generateTokenPrintData(token, doctor);
      debugPrint('📊 Generated print data: ${printData.length} bytes');

      final bluetoothService = BluetoothPrintService();

      if (!bluetoothService.isConnected) {
        debugPrint('❌ Bluetooth print failed: No printer connected');
        return false;
      }

      if (!bluetoothService.hasValidConnection) {
        debugPrint('❌ Bluetooth print failed: Invalid connection state');
        return false;
      }

      // Check if printer is ready before printing
      if (!await bluetoothService.isPrinterReady()) {
        debugPrint('❌ Bluetooth print failed: Printer not ready');
        return false;
      }

      debugPrint('🚀 Sending data to Bluetooth printer...');
      final result = await bluetoothService.printData(printData);
      debugPrint('📊 Bluetooth print result: $result');

      if (result) {
        debugPrint('✅ Bluetooth token print completed successfully!');
      } else {
        debugPrint('❌ Bluetooth token print failed!');
      }

      debugPrint('=== BLUETOOTH TOKEN PRINT COMPLETED ===');
      return result;
    } catch (e) {
      debugPrint('💥 Bluetooth printing failed with error: $e');
      debugPrint('=== BLUETOOTH TOKEN PRINT FAILED ===');
      return false;
    }
  }

  // Print multiple tokens via Bluetooth
  Future<bool> printMultipleTokensViaBluetooth(
      List<Token> tokens, Doctor doctor) async {
    try {
      debugPrint('=== STARTING BLUETOOTH MULTIPLE TOKENS PRINT ===');
      debugPrint('📊 Number of tokens: ${tokens.length}');
      debugPrint('👨‍⚕️ Doctor: ${doctor.name}');
      debugPrint(
          '🔢 Token range: ${tokens.first.tokenNumber} - ${tokens.last.tokenNumber}');

      final printData = await generateMultipleTokensPrintData(tokens, doctor);
      debugPrint('📊 Generated print data: ${printData.length} bytes');

      final bluetoothService = BluetoothPrintService();

      if (!bluetoothService.isConnected) {
        debugPrint('❌ Bluetooth print failed: No printer connected');
        return false;
      }

      if (!bluetoothService.hasValidConnection) {
        debugPrint('❌ Bluetooth print failed: Invalid connection state');
        return false;
      }

      // Check if printer is ready before printing
      if (!await bluetoothService.isPrinterReady()) {
        debugPrint('❌ Bluetooth print failed: Printer not ready');
        return false;
      }

      debugPrint('🚀 Sending data to Bluetooth printer...');
      final result = await bluetoothService.printData(printData);
      debugPrint('📊 Bluetooth print result: $result');

      if (result) {
        debugPrint('✅ Bluetooth multiple tokens print completed successfully!');
      } else {
        debugPrint('❌ Bluetooth multiple tokens print failed!');
      }

      debugPrint('=== BLUETOOTH MULTIPLE TOKENS PRINT COMPLETED ===');
      return result;
    } catch (e) {
      debugPrint('💥 Bluetooth printing failed with error: $e');
      debugPrint('=== BLUETOOTH MULTIPLE TOKENS PRINT FAILED ===');
      return false;
    }
  }

  // Get the currently connected Bluetooth printer
  BluetoothDevice? getConnectedPrinter() {
    final bluetoothService = BluetoothPrintService();
    return bluetoothService.connectedDevice;
  }

  // Check if a Bluetooth printer is connected
  bool isBluetoothPrinterConnected() {
    final bluetoothService = BluetoothPrintService();
    return bluetoothService.isConnected;
  }
}
