import '../models/medication.dart';
import 'supabase_service.dart';

class MedicationService {
  static final _db = SupabaseService.client.from('medications');

  static Future<List<Medication>> fetchMedications() async {
    final rows = await _db
        .select('*, compartments(slot_number, label)')
        .eq('user_id', SupabaseService.ownerId)
        .order('created_at');
    return rows.map((r) => Medication.fromJson(r)).toList();
  }

  static Future<Medication> addMedication({
    required String compartmentId,
    required String name,
    required String dosage,
    String? color,
    String? notes,
  }) async {
    final row = await _db
        .insert({
          'user_id': SupabaseService.ownerId,
          'compartment_id': compartmentId,
          'name': name,
          'dosage': dosage,
          'color': color,
          'notes': notes,
        })
        .select()
        .single();
    return Medication.fromJson(row);
  }

  static Future<void> updateMedication(
    String id, {
    String? name,
    String? dosage,
    String? color,
    String? notes,
  }) async {
    await _db
        .update({
          if (name != null) 'name': name,
          if (dosage != null) 'dosage': dosage,
          if (color != null) 'color': color,
          if (notes != null) 'notes': notes,
        })
        .eq('id', id);
  }

  static Future<void> deleteMedication(String id) async {
    await _db.delete().eq('id', id);
  }
}
