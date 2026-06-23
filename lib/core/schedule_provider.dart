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

  List<Schedule> byMedication(String medicationId) =>
      _schedules.where((s) => s.medicationId == medicationId).toList();

  Future<void> fetchSchedules() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _schedules = await ScheduleService.fetchSchedules();
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
    required String medicationId,
    required String compartmentId,
    required String deviceId,
    required String scheduledTime,
    required List<int> daysOfWeek,
  }) async {
    _error = null;
    try {
      final schedule = await ScheduleService.addSchedule(
        medicationId: medicationId,
        compartmentId: compartmentId,
        deviceId: deviceId,
        scheduledTime: scheduledTime,
        daysOfWeek: daysOfWeek,
      );
      _schedules.add(schedule);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    _error = null;
    try {
      await ScheduleService.toggleActive(id, isActive);
      final index = _schedules.indexWhere((s) => s.id == id);
      if (index != -1) {
        final s = _schedules[index];
        _schedules[index] = Schedule(
          id: s.id,
          medicationId: s.medicationId,
          compartmentId: s.compartmentId,
          deviceId: s.deviceId,
          userId: s.userId,
          scheduledTime: s.scheduledTime,
          daysOfWeek: s.daysOfWeek,
          isActive: isActive,
          createdAt: s.createdAt,
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
