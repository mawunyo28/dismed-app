import '../models/notification.dart';
import 'supabase_service.dart';

class NotificationService {
  static final _db = SupabaseService.client.from('notifications');

  static Future<List<DismedNotification>> fetchNotifications({bool unreadOnly = false}) async {
    var query = _db.select().eq('user_id', SupabaseService.userId);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((r) => DismedNotification.fromJson(r)).toList();
  }

  static Future<void> markRead(String id) async {
    await _db.update({'is_read': true}).eq('id', id);
  }

  static Future<void> markAllRead() async {
    await _db.update({'is_read': true}).eq('user_id', SupabaseService.userId).eq('is_read', false);
  }
}
