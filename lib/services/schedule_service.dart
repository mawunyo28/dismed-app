// services/schedule_service.dart
import '../models/schedule.dart';
import 'supabase_service.dart';

class ScheduleService {
  static final _db = SupabaseService.client.from('schedules');

  static Future<List<Schedule>> fetchSchedules(String deviceId) async {
    final rows = await _db
        .select('*, compartments(slot, medication_name)')
        .eq('device_id', deviceId)
        .order('dispense_time');
    return rows.map((r) => Schedule.fromJson(r)).toList();
  }

  static Future<List<Schedule>> fetchTodaySchedules(String deviceId) async {
    final dow = DateTime.now().weekday % 7;
    final rows = await _db
        .select()
        .eq('device_id', deviceId)
        .eq('active', true)
        .contains('days_of_week', [dow])
        .order('dispense_time');
    return rows.map((r) => Schedule.fromJson(r)).toList();
  }

  static Future<Schedule> addSchedule({
    required String deviceId,
    required String compartmentId,
    required String dispenseTime,
    required List<int> daysOfWeek,
    int pillsPerDose = 1,
  }) async {
    final row = await _db
        .insert({
          'device_id': deviceId,
          'compartment_id': compartmentId,
          'dispense_time': dispenseTime,
          'days_of_week': daysOfWeek,
          'pills_per_dose': pillsPerDose,
          'active': true,
        })
        .select()
        .single();
    return Schedule.fromJson(row);
  }

  static Future<void> toggleActive(String id, bool active) async {
    await _db.update({'active': active}).eq('id', id);
  }

  static Future<void> deleteSchedule(String id) async {
    await _db.delete().eq('id', id);
  }
}

