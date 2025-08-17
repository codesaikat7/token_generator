import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/token.dart';
import '../services/storage_service.dart';

import '../models/doctor.dart';

class PatientCard extends StatefulWidget {
  final Patient patient;
  final Doctor doctor;
  final VoidCallback onPatientDeleted;
  final Function(Token) onTokenGenerated;

  const PatientCard({
    super.key,
    required this.patient,
    required this.doctor,
    required this.onPatientDeleted,
    required this.onTokenGenerated,
  });

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  final StorageService _storageService = StorageService();
  bool _isGenerating = false;
  bool _hasToken = false;
  bool _isLoadingTokenStatus = true;

  @override
  void initState() {
    super.initState();
    _checkTokenStatus();
  }

  Future<void> _checkTokenStatus() async {
    try {
      final tokens =
          await _storageService.getTokensByPatient(widget.patient.id);
      setState(() {
        _hasToken = tokens.isNotEmpty;
        _isLoadingTokenStatus = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTokenStatus = false;
      });
    }
  }

  // Method to manually refresh token status
  Future<void> refreshTokenStatus() async {
    await _checkTokenStatus();
  }

  @override
  void didUpdateWidget(PatientCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh token status when the widget is updated
    if (oldWidget.patient.id != widget.patient.id) {
      _checkTokenStatus();
    }
  }

  Future<void> _generateToken() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final tokenNumber = await _storageService.generateToken(
        widget.patient.doctorId,
        widget.patient.id,
        widget.patient.name,
      );

      final token = Token(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tokenNumber: tokenNumber,
        patientName: widget.patient.name,
        patientId: widget.patient.id,
        doctorId: widget.patient.doctorId,
      );

      if (mounted) {
        setState(() {
          _hasToken = true;
        });
        widget.onTokenGenerated(token);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating token: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _deletePatient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content:
            Text('Are you sure you want to delete ${widget.patient.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.deletePatient(widget.patient.id);
        if (mounted) {
          widget.onPatientDeleted();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting patient: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.person,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_hasToken)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Token Generated',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    width: 85,
                    height: 24,
                    child: ElevatedButton(
                      onPressed:
                          _hasToken || _isGenerating || _isLoadingTokenStatus
                              ? null
                              : _generateToken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hasToken ? Colors.grey : Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 24),
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : _hasToken
                              ? const Icon(Icons.check_circle, size: 12)
                              : const Text(
                                  'Generate Token',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    onPressed: _deletePatient,
                    icon: const Icon(Icons.delete, color: Colors.red, size: 14),
                    tooltip: 'Delete Patient',
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      minimumSize: const Size(24, 24),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
