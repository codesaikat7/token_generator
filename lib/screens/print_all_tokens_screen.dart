import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/token.dart';
import '../models/doctor.dart';
import '../services/print_service.dart';

class PrintAllTokensScreen extends StatefulWidget {
  final List<Token> tokens;
  final Doctor doctor;

  const PrintAllTokensScreen({
    Key? key,
    required this.tokens,
    required this.doctor,
  }) : super(key: key);

  @override
  State<PrintAllTokensScreen> createState() => _PrintAllTokensScreenState();
}

class _PrintAllTokensScreenState extends State<PrintAllTokensScreen> {
  final PrintService _printService = PrintService();
  Uint8List? _printData;
  bool _isLoading = true;
  String? _error;
  late List<Token> _sortedTokens;

  @override
  void initState() {
    super.initState();
    _sortedTokens = List.from(widget.tokens)
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
    _generatePrintData();
  }

  Future<void> _generatePrintData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final printData = await _printService.generateMultipleTokensPrintData(
          widget.tokens, widget.doctor);

      setState(() {
        _printData = printData;
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
        title: const Text('Print All Tokens'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_printData != null)
            IconButton(
              onPressed: () {
                // TODO: Implement actual printing here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Print functionality coming soon!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.print),
              tooltip: 'Print All Now',
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
                        Text('Generating print data for all tokens...'),
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
                            // Token List
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Token List',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ..._sortedTokens.map(
                                        (token) => _buildTokenReceipt(token)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          // Print All Now button at bottom
          Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement actual printing here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Print functionality coming soon!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print),
                        SizedBox(width: 8),
                        Text('Print All Now'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenReceipt(Token token) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
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
            _formatDateTime(token.generatedAt),
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
          const SizedBox(height: 16),

          // Patient name and token number
          Text(
            '${token.patientName} ${token.tokenNumber}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  String _getDateRange() {
    if (widget.tokens.isEmpty) return 'No tokens';

    final dates = widget.tokens.map((t) => t.generatedAt).toList();
    dates.sort();

    final first = dates.first;
    final last = dates.last;

    if (first.day == last.day &&
        first.month == last.month &&
        first.year == last.year) {
      return '${first.day}/${first.month}/${first.year}';
    }

    return '${first.day}/${first.month}/${first.year} - ${last.day}/${last.month}/${last.year}';
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
}
