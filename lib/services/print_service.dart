import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import '../models/token.dart';
import '../models/doctor.dart';

class PrintService {
  // Generate print data for a token (for manual printing or sharing)
  Future<Uint8List> generateTokenPrintData(Token token, Doctor doctor) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

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

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Patient name and token number
    bytes += generator.text('${token.patientName} ${token.tokenNumber}',
        styles: const PosStyles(
          height: PosTextSize.size3,
          width: PosTextSize.size3,
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

    bytes +=
        generator.text('', styles: const PosStyles(height: PosTextSize.size1));

    // Cut the paper
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  // Generate print data for multiple tokens
  Future<Uint8List> generateMultipleTokensPrintData(
      List<Token> tokens, Doctor doctor) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

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

      bytes += generator.text('',
          styles: const PosStyles(height: PosTextSize.size1));

      // Patient name and token number
      bytes += generator.text('${token.patientName} ${token.tokenNumber}',
          styles: const PosStyles(
            height: PosTextSize.size3,
            width: PosTextSize.size3,
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

    // Cut the paper after all tokens
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  // Save print data to file for manual printing
  Future<String> saveTokenPrintData(Token token, Doctor doctor) async {
    try {
      final bytes = await generateTokenPrintData(token, doctor);
      // For now, we'll return a success message
      // In a real implementation, you could save to file or share
      return 'Token print data generated successfully';
    } catch (e) {
      return 'Error generating print data: $e';
    }
  }

  // Save multiple tokens print data to file
  Future<String> saveMultipleTokensPrintData(
      List<Token> tokens, Doctor doctor) async {
    try {
      final bytes = await generateMultipleTokensPrintData(tokens, doctor);
      // For now, we'll return a success message
      // In a real implementation, you could save to file or share
      return 'Multiple tokens print data generated successfully';
    } catch (e) {
      return 'Error generating print data: $e';
    }
  }
}
