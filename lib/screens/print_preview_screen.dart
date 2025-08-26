import 'package:flutter/material.dart';
import '../models/token.dart';
import '../models/doctor.dart';
import '../services/print_service.dart';
import '../services/bluetooth_print_service.dart';
import '../widgets/bluetooth_printer_dialog.dart';

class PrintPreviewScreen extends StatefulWidget {
  final List<Token> tokens;
  final Doctor doctor;
  final bool isBulkPrint;

  const PrintPreviewScreen({
    super.key,
    required this.tokens,
    required this.doctor,
    this.isBulkPrint = false,
  });

  // Factory constructor for individual token printing
  factory PrintPreviewScreen.single({
    Key? key,
    required Token token,
    required Doctor doctor,
  }) {
    return PrintPreviewScreen(
      key: key,
      tokens: [token],
      doctor: doctor,
      isBulkPrint: false,
    );
  }

  // Factory constructor for bulk token printing
  factory PrintPreviewScreen.bulk({
    Key? key,
    required List<Token> tokens,
    required Doctor doctor,
  }) {
    return PrintPreviewScreen(
      key: key,
      tokens: tokens,
      doctor: doctor,
      isBulkPrint: true,
    );
  }

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  final PrintService _printService = PrintService();
  final BluetoothPrintService _bluetoothService = BluetoothPrintService();
  bool _isLoading = true;
  bool _isPrinting = false;
  String? _error;
  bool _isPrinterConnected = false;

  @override
  void initState() {
    super.initState();
    _generatePrintData();
    // Check current printer connection status instead of clearing it
    _checkPrinterConnection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check printer connection status when dependencies change (e.g., screen comes into focus)
    _checkPrinterConnection();
  }

  void _checkPrinterConnection() {
    final hasConnection = _bluetoothService.hasValidConnection;
    debugPrint(
        'PrintPreviewScreen: Checking printer connection - hasValidConnection: $hasConnection, current _isPrinterConnected: $_isPrinterConnected');

    setState(() {
      _isPrinterConnected = hasConnection;
    });

    debugPrint(
        'PrintPreviewScreen: Updated _isPrinterConnected to: $_isPrinterConnected');
  }

  Future<void> _generatePrintData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Print Preview'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isPrinterConnected)
            IconButton(
              onPressed: _showPrinterSelection,
              icon: const Icon(Icons.bluetooth),
              tooltip: 'Change Printer',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.deepPurple),
                        SizedBox(height: 16),
                        Text('Generating print data...'),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error,
                                color: Colors.red, size: 64),
                            const SizedBox(height: 16),
                            Text('Error: $_error',
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _generatePrintData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Receipt Preview
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.isBulkPrint
                                          ? 'All Tokens Preview'
                                          : 'Token Preview',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: Column(
                                        children: [
                                          if (widget.isBulkPrint) ...[
                                            // Show all tokens in individual format
                                            ...widget.tokens.map((token) =>
                                                Column(
                                                  children: [
                                                    // Top border
                                                    Text(
                                                      '==============================',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontFamily: 'monospace',
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Date and time
                                                    Text(
                                                      _formatDateTime(
                                                          token.generatedAt),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Doctor name
                                                    Text(
                                                      'DR ${widget.doctor.name.toUpperCase()}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),

                                                    // Patient name
                                                    Text(
                                                      token.patientName,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Serial number
                                                    Text(
                                                      'Serial No - ${token.tokenNumber}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Instruction
                                                    Text(
                                                      'keep this till you are in clinic',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),

                                                    // Bottom border
                                                    Text(
                                                      '==============================',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontFamily: 'monospace',
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                  ],
                                                )),
                                          ] else ...[
                                            // Show header and single token for individual mode
                                            // Date and time
                                            Text(
                                              _formatDateTime(
                                                  widget.tokens[0].generatedAt),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Doctor name
                                            Text(
                                              'DR ${widget.doctor.name.toUpperCase()}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),

                                            // Show patient name
                                            Text(
                                              widget.tokens[0].patientName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Show serial number
                                            Text(
                                              'Serial No - ${widget.tokens[0].tokenNumber}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Instruction
                                            Text(
                                              'keep this till you are in clinic',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Bottom border
                                            Text(
                                              '==============================',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          // Print Now button at bottom
          Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isPrinterConnected && !_isPrinting)
                        ? _printToken
                        : (_isPrinting ? null : _showPrinterSelection),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isPrinting ? Colors.grey[400] : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isPrinting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Icon(_isPrinterConnected
                              ? Icons.print
                              : Icons.bluetooth),
                        const SizedBox(width: 8),
                        Text(_isPrinting
                            ? 'Printing...'
                            : (_isPrinterConnected
                                ? (widget.isBulkPrint
                                    ? 'Print All Now'
                                    : 'Print Now')
                                : 'Select Printer')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
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
    final monthName = monthNames[dateTime.month - 1];
    final timeFormat =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$monthName ${dateTime.day}, ${dateTime.year} $timeFormat';
  }

  void _showPrinterSelection() {
    showDialog(
      context: context,
      builder: (context) => BluetoothPrinterDialog(
        onPrinterSelected: (device) async {
          // Refresh the connection status after dialog closes
          // Add a small delay to ensure the dialog state is fully processed
          await Future.delayed(const Duration(milliseconds: 100));
          _checkPrinterConnection();
        },
      ),
    ).then((_) {
      // Also check connection when dialog is dismissed (in case user just closes it)
      Future.delayed(const Duration(milliseconds: 100), () {
        _checkPrinterConnection();
      });
    });
  }

  Future<void> _printToken() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      // Add a small delay to ensure the UI updates before starting print
      await Future.delayed(const Duration(milliseconds: 100));

      final success = widget.isBulkPrint
          ? await _printService.printMultipleTokensViaBluetooth(
              widget.tokens, widget.doctor)
          : await _printService.printTokenViaBluetooth(
              widget.tokens[0], widget.doctor);

      // Add a small delay to ensure printing completes
      await Future.delayed(const Duration(milliseconds: 500));

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isBulkPrint
                  ? 'All tokens printed successfully!'
                  : 'Token printed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isBulkPrint
                  ? 'Failed to print tokens. Please check printer connection and try again.'
                  : 'Failed to print token. Please check printer connection and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }
}
