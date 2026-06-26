// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class NotificationPushService {
//   static const _oneSignalAppId = 'beeedd9d-4bad-450c-aa8e-45e57dd74677';
//
//   static Future<void> init() async {
//     OneSignal.initialize(_oneSignalAppId);
//
//     await OneSignal.Notifications.requestPermission(true);
//
//     await _savePlayerId();
//
//     OneSignal.Notifications.addForegroundWillDisplayListener((event) {
//       final event.notification.additionalData;
//
//
//     })
//   }
// }
