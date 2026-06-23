import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<DismedNotification> _notifications = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<DismedNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await NotificationService.fetchNotifications(unreadOnly: unreadOnly);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(String id) async {
    _error = null;
    try {
      await NotificationService.markRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final n = _notifications[index];
        _notifications[index] = DismedNotification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    _error = null;
    try {
      await NotificationService.markAllRead();
      _notifications = _notifications
          .map(
            (n) => DismedNotification(
              id: n.id,
              userId: n.userId,
              type: n.type,
              message: n.message,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void subscribeRealtime(String userId) {
    _channel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = DismedNotification.fromJson(payload.newRecord);
            _notifications.insert(0, notification);
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
