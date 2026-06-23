import '../models/compartment.dart';
import 'supabase_service.dart';

class CompartmentService {
  static final _db = SupabaseService.client.from('compartments');

  static Future<List<Compartment>> fetchCompartments(String deviceId) async {
    final rows = await _db.select().eq('device_id', deviceId).order('slot_number');
    return rows.map((r) => Compartment.fromJson(r)).toList();
  }

  static Future<void> updateLabel(String id, String label) async {
    await _db.update({'label': label}).eq('id', id);
  }

  static Future<void> updateCapacity(String id, int capacity) async {
    await _db.update({'capacity': capacity}).eq('id', id);
  }

  static Future<void> refill(String id, int capacity) async {
    await _db.update({'current_count': capacity}).eq('id', id);
  }

  static Future<void> manualDispense(String id) async {
    await _db.update({'pending_dispense': true}).eq('id', id);
  }

  static Future<void> clearPendingDispense(String id) async {
    await _db.update({'pending_dispense': false}).eq('id', id);
  }
}
