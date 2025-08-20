import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/token.dart';
import '../models/doctor.dart';
import '../screens/print_preview_screen.dart';

class TokenCard extends StatelessWidget {
  final Token token;
  final Doctor doctor;

  const TokenCard({super.key, required this.token, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  '#${token.tokenNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(token.generatedAt)} at ${timeFormat.format(token.generatedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PrintPreviewScreen.single(
                      token: token,
                      doctor: doctor,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.print, color: Colors.orange),
              tooltip: 'Print Token',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
