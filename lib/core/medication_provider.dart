import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  List<Medication> _medications = [];
  bool _loading = false;
  String? _error;

  List<Medication> get medications => _medications;
  bool get loading => _loading;
  String? get error => _error;

  List<Medication> byCompartment(String compartmentId) =>
      _medications.where((m) => m.compartmentId == compartmentId).toList();

  Future<void> fetchMedications() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _medications = await MedicationService.fetchMedications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication({
    required String compartmentId,
    required String name,
    required String dosage,
    String? color,
    String? notes,
  }) async {
    _error = null;
    try {
      final medication = await MedicationService.addMedication(
        compartmentId: compartmentId,
        name: name,
        dosage: dosage,
        color: color,
        notes: notes,
      );
      _medications.add(medication);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMedication(
    String id, {
    String? name,
    String? dosage,
    String? color,
    String? notes,
  }) async {
    _error = null;
    try {
      await MedicationService.updateMedication(
        id,
        name: name,
        dosage: dosage,
        color: color,
        notes: notes,
      );
      final index = _medications.indexWhere((m) => m.id == id);
      if (index != -1) {
        final m = _medications[index];
        _medications[index] = Medication(
          id: m.id,
          compartmentId: m.compartmentId,
          name: name ?? m.name,
          dosage: dosage ?? m.dosage,
          color: color ?? m.color,
          notes: notes ?? m.notes,
          createdAt: m.createdAt,
          deviceId: m.deviceId,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    _error = null;
    try {
      await MedicationService.deleteMedication(id);
      _medications.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
