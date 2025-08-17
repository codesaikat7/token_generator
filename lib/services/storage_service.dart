import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/token.dart';

class StorageService extends ChangeNotifier {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;

  StorageService._internal();

  static const String _doctorsKey = 'doctors';
  static const String _patientsKey = 'patients';
  static const String _tokensKey = 'tokens';

  // Doctor management
  Future<List<Doctor>> getDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorsJson = prefs.getStringList(_doctorsKey) ?? [];

    return doctorsJson
        .map((json) => Doctor.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addDoctor(Doctor doctor) async {
    final doctors = await getDoctors();

    // Check if doctor with same name already exists
    if (doctors.any((d) => d.name.toLowerCase() == doctor.name.toLowerCase())) {
      throw Exception('A doctor with this name already exists');
    }

    doctors.add(doctor);
    await _saveDoctors(doctors);
  }

  Future<void> updateDoctor(Doctor doctor) async {
    final doctors = await getDoctors();

    final index = doctors.indexWhere((d) => d.id == doctor.id);
    if (index != -1) {
      doctors[index] = doctor;
      await _saveDoctors(doctors);
    }
  }

  Future<void> deleteDoctor(String doctorId) async {
    final doctors = await getDoctors();

    doctors.removeWhere((d) => d.id == doctorId);
    await _saveDoctors(doctors);

    // Also delete all patients and tokens associated with this doctor
    await deletePatientsByDoctor(doctorId);
    await deleteTokensByDoctor(doctorId);
  }

  Future<void> _saveDoctors(List<Doctor> doctors) async {
    final prefs = await SharedPreferences.getInstance();
    final doctorsJson =
        doctors.map((doctor) => jsonEncode(doctor.toJson())).toList();

    await prefs.setStringList(_doctorsKey, doctorsJson);
  }

  // Patient management
  Future<List<Patient>> getPatientsByDoctor(String doctorId) async {
    final prefs = await SharedPreferences.getInstance();
    final patientsJson = prefs.getStringList(_patientsKey) ?? [];

    final allPatients =
        patientsJson.map((json) => Patient.fromJson(jsonDecode(json))).toList();

    return allPatients
        .where((patient) => patient.doctorId == doctorId)
        .toList();
  }

  Future<void> addPatient(Patient patient) async {
    final prefs = await SharedPreferences.getInstance();
    final patients = await getPatientsByDoctor(patient.doctorId);

    // Check if patient with same name already exists for this doctor
    if (patients
        .any((p) => p.name.toLowerCase() == patient.name.toLowerCase())) {
      throw Exception(
          'A patient with this name already exists for this doctor');
    }

    final allPatientsJson = prefs.getStringList(_patientsKey) ?? [];
    final allPatients = allPatientsJson
        .map((json) => Patient.fromJson(jsonDecode(json)))
        .toList();

    allPatients.add(patient);
    await _savePatients(allPatients);

    // Notify all patient count widgets to refresh
    notifyPatientCountChanged();
  }

  Future<void> deletePatient(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final allPatientsJson = prefs.getStringList(_patientsKey) ?? [];

    final allPatients = allPatientsJson
        .map((json) => Patient.fromJson(jsonDecode(json)))
        .toList();

    allPatients.removeWhere((p) => p.id == patientId);
    await _savePatients(allPatients);

    // Also delete all tokens associated with this patient
    await deleteTokensByPatient(patientId);

    // Notify all patient count widgets to refresh
    notifyPatientCountChanged();
  }

  Future<void> deletePatientsByDoctor(String doctorId) async {
    final prefs = await SharedPreferences.getInstance();
    final allPatientsJson = prefs.getStringList(_patientsKey) ?? [];

    final allPatients = allPatientsJson
        .map((json) => Patient.fromJson(jsonDecode(json)))
        .toList();

    final patientIdsToDelete = allPatients
        .where((p) => p.doctorId == doctorId)
        .map((p) => p.id)
        .toList();

    for (final patientId in patientIdsToDelete) {
      await deletePatient(patientId);
    }

    // Note: No need to call notifyPatientCountChanged() here as deletePatient already does it
  }

  Future<void> _savePatients(List<Patient> patients) async {
    final prefs = await SharedPreferences.getInstance();
    final patientsJson =
        patients.map((patient) => jsonEncode(patient.toJson())).toList();

    await prefs.setStringList(_patientsKey, patientsJson);
  }

  // Token management
  Future<int> generateToken(
      String doctorId, String patientId, String patientName) async {
    final tokens = await getTokensByDoctor(doctorId);

    // Check if patient already has a token
    final existingToken = tokens.any((token) => token.patientId == patientId);
    if (existingToken) {
      throw Exception('A token has already been generated for this patient');
    }

    final today = DateTime.now();

    // Filter tokens for today
    final todayTokens = tokens.where((token) {
      final tokenDate = DateTime(
        token.generatedAt.year,
        token.generatedAt.month,
        token.generatedAt.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);
      return tokenDate.isAtSameMomentAs(todayDate);
    }).toList();

    // Generate next token number
    final nextTokenNumber = todayTokens.isEmpty
        ? 1
        : todayTokens
                .map((t) => t.tokenNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;

    // Create new token
    final newToken = Token(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tokenNumber: nextTokenNumber,
      patientName: patientName,
      patientId: patientId,
      doctorId: doctorId,
    );

    // Save token
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    allTokens.add(newToken);
    await _saveAllTokens(allTokens);

    // Update doctor's last token information
    await _updateDoctorLastToken(doctorId, nextTokenNumber, today);

    return nextTokenNumber;
  }

  Future<void> _updateDoctorLastToken(
      String doctorId, int tokenNumber, DateTime tokenDate) async {
    final allDoctors = await getDoctors();

    // Find and update the specific doctor
    final doctorIndex =
        allDoctors.indexWhere((doctor) => doctor.id == doctorId);
    if (doctorIndex != -1) {
      final updatedDoctor = allDoctors[doctorIndex].copyWith(
        lastTokenNumber: tokenNumber,
        lastTokenDate: tokenDate,
      );
      allDoctors[doctorIndex] = updatedDoctor;

      // Save updated doctors list
      await _saveDoctors(allDoctors);
    }
  }

  Future<void> _resetDoctorLastToken(String doctorId) async {
    final allDoctors = await getDoctors();

    // Find and reset the specific doctor's token information
    final doctorIndex =
        allDoctors.indexWhere((doctor) => doctor.id == doctorId);
    if (doctorIndex != -1) {
      final updatedDoctor = allDoctors[doctorIndex].copyWith(
        lastTokenNumber: 0,
        lastTokenDate: DateTime.now(),
      );
      allDoctors[doctorIndex] = updatedDoctor;

      // Save updated doctors list
      await _saveDoctors(allDoctors);
    }
  }

  Future<void> _updateDoctorLastTokenFromRemainingTokens(
      String doctorId) async {
    final allDoctors = await getDoctors();
    final remainingTokens = await getTokensByDoctor(doctorId);

    // Find the specific doctor
    final doctorIndex =
        allDoctors.indexWhere((doctor) => doctor.id == doctorId);
    if (doctorIndex != -1) {
      int lastTokenNumber = 0;
      DateTime lastTokenDate = DateTime.now();

      if (remainingTokens.isNotEmpty) {
        // Find the highest token number among remaining tokens
        lastTokenNumber = remainingTokens
            .map((token) => token.tokenNumber)
            .reduce((a, b) => a > b ? a : b);

        // Find the most recent token date
        lastTokenDate = remainingTokens
            .map((token) => token.generatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }

      final updatedDoctor = allDoctors[doctorIndex].copyWith(
        lastTokenNumber: lastTokenNumber,
        lastTokenDate: lastTokenDate,
      );
      allDoctors[doctorIndex] = updatedDoctor;

      // Save updated doctors list
      await _saveDoctors(allDoctors);
    }
  }

  Future<List<Token>> getTokensByDoctor(String doctorId) async {
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    return allTokens.where((token) => token.doctorId == doctorId).toList();
  }

  Future<List<Token>> getTokensByPatient(String patientId) async {
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    return allTokens.where((token) => token.patientId == patientId).toList();
  }

  Future<void> deleteTokensByDoctor(String doctorId) async {
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    allTokens.removeWhere((t) => t.doctorId == doctorId);
    await _saveAllTokens(allTokens);

    // Reset the doctor's last token information since all tokens are deleted
    await _resetDoctorLastToken(doctorId);
  }

  Future<void> deleteTokensByPatient(String patientId) async {
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    // Find the doctor ID before removing the token
    String? doctorId;
    final tokenToDelete = allTokens.firstWhere(
      (t) => t.patientId == patientId,
      orElse: () => Token(
        id: '',
        tokenNumber: 0,
        patientName: '',
        patientId: '',
        doctorId: '',
      ),
    );
    doctorId = tokenToDelete.doctorId;

    allTokens.removeWhere((t) => t.patientId == patientId);
    await _saveAllTokens(allTokens);

    // Update the doctor's last token information based on remaining tokens
    if (doctorId.isNotEmpty) {
      await _updateDoctorLastTokenFromRemainingTokens(doctorId);
    }
  }

  // Reset all tokens functionality
  Future<void> resetAllTokens() async {
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    // Clear all tokens
    allTokens.clear();
    await _saveAllTokens(allTokens);

    // Reset all doctors' last token information
    final allDoctors = await getDoctors();
    for (final doctor in allDoctors) {
      await _resetDoctorLastToken(doctor.id);
    }
  }

  Future<void> resetTokensByDoctor(String doctorId) async {
    final allTokensJson = await _getAllTokensJson();
    final allTokens =
        allTokensJson.map((json) => Token.fromJson(jsonDecode(json))).toList();

    // Remove only tokens for specific doctor
    allTokens.removeWhere((t) => t.doctorId == doctorId);
    await _saveAllTokens(allTokens);

    // Reset the doctor's last token information
    await _resetDoctorLastToken(doctorId);
  }

  Future<List<String>> _getAllTokensJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_tokensKey) ?? [];
  }

  Future<void> _saveAllTokens(List<Token> tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final tokensJson =
        tokens.map((token) => jsonEncode(token.toJson())).toList();

    await prefs.setStringList(_tokensKey, tokensJson);
  }

  // Method to notify patient count changes
  void notifyPatientCountChanged() {
    notifyListeners();
  }
}
