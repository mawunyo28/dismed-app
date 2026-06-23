import 'package:flutter/material.dart';
import '../models/compartment.dart';
import '../services/compartment_service.dart';

class CompartmentProvider extends ChangeNotifier {
  List<Compartment> _compartments = [];
  bool _loading = false;
  String? _error;

  List<Compartment> get compartments => _compartments;
  bool get loading => _loading;
  String? get error => _error;

  Compartment? bySlot(int slot) {
    try {
      return _compartments.firstWhere((c) => c.slot == slot);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchCompartments(String deviceId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _compartments = await CompartmentService.fetchCompartments(deviceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
Future<void> updateMedication(
  String id, {
  required String medicationName,
  double? dosageMg,
}) async {
  _error = null;
  try {
    await CompartmentService.updateMedication(
      id,
      medicationName: medicationName,
      dosageMg: dosageMg,
    );
    _updateLocal(id, (c) => Compartment(
      id: c.id,
      deviceId: c.deviceId,
      slot: c.slot,
      medicationName: medicationName,
      dosageMg: dosageMg ?? c.dosageMg,
      pillCount: c.pillCount,
      capacity: c.capacity,
      updatedAt: DateTime.now(),
    ));
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}  Future<void> updateCapacity(String id, int capacity) async {
    _error = null;
    try {
      await CompartmentService.updateCapacity(id, capacity);
      _updateLocal(id, (c) => _copyWith(c, capacity: capacity));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refill(String id) async {
    _error = null;
    try {
      final compartment = _compartments.firstWhere((c) => c.id == id);
      await CompartmentService.refill(id, compartment.capacity);
      _updateLocal(id, (c) => _copyWith(c, currentCount: c.capacity));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

// in compartment_provider.dart — replace manualDispense method
Future<void> manualDispense(String compartmentId) async {
  _error = null;
  try {
    final comp = _compartments.firstWhere((c) => c.id == compartmentId);
    await CompartmentService.manualDispense(comp.deviceId, comp.slot);
    // no local state change needed — ESP32 picks it up and posts back
    // dispense_events Realtime will update the dashboard feed
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}  // called by Realtime when ESP32 clears the flag


  void updateFromRealtime(Map<String, dynamic> row) {
    final updated = Compartment.fromJson(row);
    _updateLocal(updated.id, (_) => updated);
  }

  void _updateLocal(String id, Compartment Function(Compartment) update) {
    final index = _compartments.indexWhere((c) => c.id == id);
    if (index != -1) {
      _compartments[index] = update(_compartments[index]);
      notifyListeners();
    }
  }

  Compartment _copyWith(
    Compartment c, {
    String? label,
    int? capacity,
    int? currentCount,
    bool? pendingDispense,
  }) {
    return Compartment(
      id: c.id,
      deviceId: c.deviceId,
      slot: c.slot,
      medicationName: label ?? c.medicationName,
      pillCount: currentCount ?? c.pillCount,
      capacity: capacity ?? c.capacity,
      updatedAt: c.updatedAt,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
