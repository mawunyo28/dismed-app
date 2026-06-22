import '../models/device.dart';
import 'supabase_service.dart';

class DeviceService {
  static final _db = SupabaseService.client.from('devices');

  static Future<List<Device>> fetchDevices() async {
    final rows = await _db.select().eq('user_id', SupabaseService.userId).order('created_at');
    return rows.map((r) => Device.fromJson(r)).toList();
  }

  static Future<Device> addDevice(String name, String deviceKey) async {
    final row = await _db
        .insert({'user_id': SupabaseService.userId, 'name': name, 'device_key': deviceKey})
        .select()
        .single();
    return Device.fromJson(row);
  }

  static Future<void> renameDevice(String id, String name) async {
    await _db.update({'name': name}).eq('id', id);
  }

  static Future<void> deleteDevice(String id) async {
    await _db.delete().eq('id', id);
  }
}
