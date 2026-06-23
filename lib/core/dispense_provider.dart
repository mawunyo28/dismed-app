import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dispense_log.dart';
import '../services/dispense_service.dart';

class DispenseProvider extends ChangeNotifier {
  List<DispenseEvent> _logs = [];
  List<DispenseEvent> _todayLogs = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<DispenseEvent> get logs => _logs;
  List<DispenseEvent> get todayLogs => _todayLogs;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchRecentLogs(String deviceId, {int days = 7}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _logs = await DispenseService.fetchRecentEvents(deviceId, days: days);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodayLogs(String deviceId) async {
    _error = null;
    try {
      _todayLogs = await DispenseService.fetchTodayEvents(deviceId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void subscribeRealtime(String deviceId) {
    _channel = Supabase.instance.client
        .channel('dispense_logs:$deviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dispense_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) {
            final log = DispenseEvent.fromJson(payload.newRecord);
            _logs.insert(0, log);
            // also add to today if dispensed today
            final today = DateTime.now();
            if (log.dispensedAt.year == today.year &&
                log.dispensedAt.month == today.month &&
                log.dispensedAt.day == today.day) {
              _todayLogs.insert(0, log);
            }
            notifyListeners();
          },
        )
        .subscribe();
  }

  void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
