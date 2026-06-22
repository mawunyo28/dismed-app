import '../models/schedule.dart';
import 'supabase_service.dart';

class ScheduleService {
  static final _db = SupabaseService.client.from('schedules');

  static Future<List<Schedule>> fetchSchedules() async {
    final rows = await _db
        .select('*, medications(name), compartments(slot_number, label)')
        .eq('user_id', SupabaseService.userId)
        .order('scheduled_time');
    return rows.map((r) => Schedule.fromJson(r)).toList();
  }

  static Future<List<Schedule>> fetchTodaySchedules(String deviceId) async {
    final dow = DateTime.now().weekday % 7; // converts Mon=1 to Sun=0 encoding
    final rows = await _db
        .select()
        .eq('device_id', deviceId)
        .eq('is_active', true)
        .contains('days_of_week', [dow])
        .order('scheduled_time');
    return rows.map((r) => Schedule.fromJson(r)).toList();
  }

  static Future<Schedule> addSchedule({
    required String medicationId,
    required String compartmentId,
    required String deviceId,
    required String scheduledTime,
    required List<int> daysOfWeek,
  }) async {
    final row = await _db
        .insert({
          'user_id': SupabaseService.userId,
          'medication_id': medicationId,
          'compartment_id': compartmentId,
          'device_id': deviceId,
          'scheduled_time': scheduledTime,
          'days_of_week': daysOfWeek,
          'is_active': true,
        })
        .select()
        .single();
    return Schedule.fromJson(row);
  }

  static Future<void> toggleActive(String id, bool isActive) async {
    await _db.update({'is_active': isActive}).eq('id', id);
  }

  static Future<void> deleteSchedule(String id) async {
    await _db.delete().eq('id', id);
  }
}
