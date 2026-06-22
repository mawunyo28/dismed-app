import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';

class ProxyService {
  static final String _base = dotenv.get("VERCEL_API_BASE");

  static Future<bool> manualDispense({
    required String deviceKey,
    required String compartmentId,
    required String deviceId,
  }) async {
    final res = await post(
      Uri.parse("$_base/device/manual-dispense"),
      headers: {'Content-Type': "application/json"},
      body: jsonEncode({
        'deviceKey': deviceKey,
        'compartment_id': compartmentId,
        'device_id': deviceId,
      }),
    );

    return res.statusCode == 200;
  }
}
