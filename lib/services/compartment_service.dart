// services/compartment_service.dart
import '../models/compartment.dart';
import 'supabase_service.dart';

class CompartmentService {
  static final _db = SupabaseService.client.from('compartments');

  static Future<List<Compartment>> fetchCompartments(String deviceId) async {
    final rows = await _db.select().eq('device_id', deviceId).order('slot');
    return rows.map((r) => Compartment.fromJson(r)).toList();
  }

  static Future<void> updateMedication(
    String id, {
    required String medicationName,
    double? dosageMg,
  }) async {
    await _db
        .update({
          'medication_name': medicationName,
          if (dosageMg != null) 'dosage_mg': dosageMg,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  static Future<void> updateCapacity(String id, int capacity) async {
    await _db
        .update({'capacity': capacity, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  static Future<void> refill(String id, int capacity) async {
    await _db
        .update({'pill_count': capacity, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // Manual dispense — inserts into dispense_commands
  // ESP32 polls commands route and clears it
  static Future<void> manualDispense(String deviceId, int slot) async {
    await SupabaseService.client.from('dispense_commands').insert({
      'device_id': deviceId,
      'slot': slot,
      'status': 'pending',
    });
  }
}

