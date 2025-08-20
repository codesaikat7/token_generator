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
  final StorageService _storageService = StorageService.instance;
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  GlobalKey _doctorListKey = GlobalKey();
  // Add a map to store patient counts for each doctor
  Map<String, int> _doctorPatientCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doctors = await _storageService.getDoctors();

      // Fetch patient counts for each doctor
      final patientCounts = <String, int>{};
      for (final doctor in doctors) {
        final patients = await _storageService.getPatientsByDoctor(doctor.id);
        patientCounts[doctor.id] = patients.length;
      }

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _doctorPatientCounts = patientCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctors: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addDoctor() async {
    final result = await showDialog<Doctor>(
      context: context,
      builder: (context) => const AddDoctorDialog(),
    );

    if (result != null) {
      await _storageService.addDoctor(result);
      await _loadDoctors(); // Refresh doctors and patient counts
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
      await _loadDoctors(); // Refresh doctors and patient counts
    }
  }

  Future<void> _refreshDoctorList() async {
    setState(() {
      _doctorListKey = GlobalKey();
    });
    await _loadDoctors(); // Refresh doctors and patient counts
  }

  Future<void> _showDeleteAllDoctorsDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Doctors'),
        content: const Text(
          'Are you sure you want to delete ALL doctors? '
          'This action cannot be undone and will also delete all associated patients and tokens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.deleteAllDoctors();
        await _loadDoctors(); // Refresh doctors and patient counts

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All doctors have been deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting patients: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('QueueMed'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_doctors.isNotEmpty)
            IconButton(
              onPressed: _showDeleteAllDoctorsDialog,
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete All Doctors',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _doctors.isEmpty
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
                  key: _doctorListKey,
                  padding: const EdgeInsets.all(16),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    final patientCount = _doctorPatientCounts[doctor.id] ?? 0;
                    return DoctorCard(
                      key: ValueKey(doctor.id),
                      doctor: doctor,
                      patientCount: patientCount,
                      onDelete: () => _deleteDoctor(doctor),
                      onTap: () async => await _refreshDoctorList(),
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
