import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/token.dart';
import '../services/storage_service.dart';
import '../widgets/add_patient_dialog.dart';
import '../widgets/patient_card.dart';
import '../widgets/token_card.dart';

import '../screens/print_all_tokens_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen>
    with TickerProviderStateMixin {
  final StorageService _storageService = StorageService.instance;
  late TabController _tabController;
  List<Patient> _patients = [];
  List<Token> _tokens = [];
  bool _isLoading = true;
  // Add a callback mechanism for faster updates
  final List<Function()> _refreshCallbacks = [];
  // Add a map to store patient token status for instant access
  Map<String, bool> _patientTokenStatus = {};

  // Method to register refresh callbacks
  void _registerRefreshCallback(Function() callback) {
    _refreshCallbacks.add(callback);
  }

  // Method to unregister refresh callbacks
  void _unregisterRefreshCallback(Function() callback) {
    _refreshCallbacks.remove(callback);
  }

  // Method to notify all PatientCard widgets to refresh
  void _notifyPatientCardsToRefresh() {
    // Update the token status map first
    for (final patient in _patients) {
      _patientTokenStatus[patient.id] =
          _tokens.any((token) => token.patientId == patient.id);
    }

    // Then notify widgets to refresh
    for (final callback in _refreshCallbacks) {
      callback();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patients =
          await _storageService.getPatientsByDoctor(widget.doctor.id);
      final tokens = await _storageService.getTokensByDoctor(widget.doctor.id);

      // Sort patients by ID (newest first) - since ID is timestamp
      patients.sort((a, b) => b.id.compareTo(a.id));

      // Sort tokens by token number (ascending order)
      tokens.sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));

      // Create a map of patient ID to token status for instant access
      final patientTokenStatus = <String, bool>{};
      for (final patient in patients) {
        patientTokenStatus[patient.id] =
            tokens.any((token) => token.patientId == patient.id);
      }

      setState(() {
        _patients = patients;
        _tokens = tokens;
        _patientTokenStatus = patientTokenStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addPatient() async {
    final result = await showDialog<Patient>(
      context: context,
      builder: (context) => AddPatientDialog(doctorId: widget.doctor.id),
    );

    if (result != null) {
      try {
        await _storageService.addPatient(result);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding patient: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _onPatientDeleted() {
    // Refresh the data
    _loadData();
  }

  void _onTokenGenerated(Token token) {
    // Update the patient token status immediately
    _patientTokenStatus[token.patientId] = true;
    setState(() {}); // Trigger UI update

    _loadData(); // Reload data in background
    _showTokenGeneratedDialog(token);
  }

  Future<void> _printAllTokens() async {
    if (_tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tokens to print'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Navigate to print all tokens screen
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PrintAllTokensScreen(
              tokens: _tokens,
              doctor: widget.doctor,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening print preview: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTokenGeneratedDialog(Token token) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    'Token Generated!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Icon
                  const Icon(
                    Icons.confirmation_number,
                    size: 60,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),

                  // Token Number
                  Text(
                    'Token #${token.tokenNumber}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Patient Name
                  Text(
                    'Patient: ${token.patientName}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),

                  // Doctor Name
                  Text(
                    'Dr. ${widget.doctor.name}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetTokensDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Tokens'),
        content: const Text(
          'Are you sure you want to reset all tokens for this doctor? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              try {
                await _storageService.resetTokensByDoctor(widget.doctor.id);
                await _loadData();
                // Notify PatientCard widgets to refresh their token status
                if (mounted) {
                  _notifyPatientCardsToRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All tokens reset successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error resetting tokens: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Dr. ${widget.doctor.name}'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _printAllTokens,
            icon: const Icon(Icons.print),
            tooltip: 'Print All Tokens',
          ),
          IconButton(
            onPressed: _showResetTokensDialog,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset All Tokens',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color.fromARGB(255, 168, 167, 167),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Patients', icon: Icon(Icons.people)),
            Tab(text: 'Tokens', icon: Icon(Icons.confirmation_number)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Patients Tab
          _buildPatientsTab(),
          // Tokens Tab
          _buildTokensTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPatient,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildPatientsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No patients added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first patient to start generating tokens',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _patients
            .map((patient) => PatientCard(
                  key: ValueKey(patient.id),
                  patient: patient,
                  doctor: widget.doctor,
                  hasToken: _patientTokenStatus[patient.id] ?? false,
                  onPatientDeleted: _onPatientDeleted,
                  onTokenGenerated: _onTokenGenerated,
                  onRegisterRefresh: _registerRefreshCallback,
                  onUnregisterRefresh: _unregisterRefreshCallback,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTokensTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tokens.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tokens generated yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Generate tokens for patients to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _tokens
            .map((token) => TokenCard(token: token, doctor: widget.doctor))
            .toList(),
      ),
    );
  }
}
