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
      return _compartments.firstWhere((c) => c.slotNumber == slot);
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

  Future<void> updateLabel(String id, String label) async {
    _error = null;
    try {
      await CompartmentService.updateLabel(id, label);
      _updateLocal(id, (c) => _copyWith(c, label: label));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCapacity(String id, int capacity) async {
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

  Future<void> manualDispense(String id) async {
    _error = null;
    try {
      await CompartmentService.manualDispense(id);
      // optimistically flag as pending — ESP32 will clear it
      _updateLocal(id, (c) => _copyWith(c, pendingDispense: true));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // called by Realtime when ESP32 clears the flag
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
      slotNumber: c.slotNumber,
      label: label ?? c.label,
      currentCount: currentCount ?? c.currentCount,
      capacity: capacity ?? c.capacity,
      pendingDispense: pendingDispense ?? c.pendingDispense,
      createdAt: c.createdAt,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
