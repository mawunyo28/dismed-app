import '../models/dispense_log.dart';
import 'supabase_service.dart';

class DispenseService {
  static final _db = SupabaseService.client.from('dispense_logs');

  static Future<List<DispenseLog>> fetchRecentLogs(String deviceId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final rows = await _db
        .select()
        .eq('device_id', deviceId)
        .gte('dispensed_at', since)
        .order('dispensed_at', ascending: false);
    return rows.map((r) => DispenseLog.fromJson(r)).toList();
  }

  static Future<List<DispenseLog>> fetchTodayLogs(String deviceId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final rows = await _db
        .select()
        .eq('device_id', deviceId)
        .gte('dispensed_at', startOfDay)
        .order('dispensed_at', ascending: false);
    return rows.map((r) => DispenseLog.fromJson(r)).toList();
  }
}
