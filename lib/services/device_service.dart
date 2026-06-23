// services/device_service.dart
import '../models/device.dart';
import 'supabase_service.dart';

class DeviceService {
  static final _db = SupabaseService.client.from('devices');

  static Future<List<Device>> fetchDevices() async {
    final rows = await _db.select().eq('owner_id', SupabaseService.ownerId).order('created_at');
    return rows.map((r) => Device.fromJson(r)).toList();
  }

  static Future<Device> addDevice(String label, String deviceKey) async {
    final row = await _db
        .insert({'owner_id': SupabaseService.ownerId, 'label': label, 'device_key': deviceKey})
        .select()
        .single();
    return Device.fromJson(row);
  }

  static Future<void> renameDevice(String id, String label) async {
    await _db.update({'label': label}).eq('id', id);
  }

  static Future<void> deleteDevice(String id) async {
    await _db.delete().eq('id', id);
  }
}

