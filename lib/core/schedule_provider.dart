import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';

class ScheduleProvider extends ChangeNotifier {
  List<Schedule> _schedules = [];
  List<Schedule> _todaySchedules = [];
  bool _loading = false;
  String? _error;

  List<Schedule> get schedules => _schedules;
  List<Schedule> get todaySchedules => _todaySchedules;
  bool get loading => _loading;
  String? get error => _error;

  // List<Schedule> byMedication(String medicationId) =>
  //     _schedules.where((s) => s.medicationId == medicationId).toList();

  Future<void> fetchSchedules(String deviceId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _schedules = await ScheduleService.fetchSchedules(deviceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodaySchedules(String deviceId) async {
    _error = null;
    try {
      _todaySchedules = await ScheduleService.fetchTodaySchedules(deviceId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addSchedule({
    required String deviceId,
    required String compartmentId,
    required String dispenseTime,
    required List<int> daysOfWeek,
    int pillsPerDose = 1,
  }) async {
    _error = null;
    try {
      final schedule = await ScheduleService.addSchedule(
        compartmentId: compartmentId,
        dispenseTime: dispenseTime,
        deviceId: deviceId,
        daysOfWeek: daysOfWeek,
        pillsPerDose: pillsPerDose,
      );
      _schedules.add(schedule);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleActive(String id, bool active) async {
    _error = null;
    try {
      await ScheduleService.toggleActive(id, active);
      final index = _schedules.indexWhere((s) => s.id == id);
      if (index != -1) {
        final s = _schedules[index];
        _schedules[index] = Schedule(
          id: s.id,
          compartmentId: s.compartmentId,
          deviceId: s.deviceId,
          dispenseTime: s.dispenseTime,
          daysOfWeek: s.daysOfWeek,
          active: active,
          createdAt: s.createdAt,
          pillsPerDose: s.pillsPerDose,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    _error = null;
    try {
      await ScheduleService.deleteSchedule(id);
      _schedules.removeWhere((s) => s.id == id);
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
