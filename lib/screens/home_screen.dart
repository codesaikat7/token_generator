import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/storage_service.dart';
import '../widgets/doctor_card.dart';
import '../widgets/add_doctor_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<Doctor> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final doctors = await _storageService.getDoctors();
    setState(() {
      _doctors = doctors;
    });
  }

  Future<void> _addDoctor() async {
    final result = await showDialog<Doctor>(
      context: context,
      builder: (context) => const AddDoctorDialog(),
    );

    if (result != null) {
      await _storageService.addDoctor(result);
      _loadDoctors();
    }
  }

  Future<void> _deleteDoctor(Doctor doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text(
            'Are you sure you want to delete Dr. ${doctor.name}? This will also delete all associated patients and tokens.'),
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
      await _storageService.deleteDoctor(doctor.id);
      _loadDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Token Generator'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _doctors.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No doctors added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first doctor to start managing patients and tokens',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return DoctorCard(
                  doctor: doctor,
                  onDelete: () => _deleteDoctor(doctor),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDoctor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
