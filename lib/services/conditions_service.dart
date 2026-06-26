import 'package:dismed/services/supabase_service.dart';

class ConditionsService {
  static final _db = SupabaseService.client.from("medibot");

  static Future<double> getTemperature() async {
    try {
      final row = await _db
          .select("temperature")
          .order("created_at", ascending: false)
          .limit(1)
          .single();

      // 1. Check your terminal for this print statement:
      print("DEBUG Temp Row: $row");

      return (row["temperature"] as num).toDouble();
    } catch (e) {
      print("DEBUG Temp Error: $e");
      rethrow;
    }
  }

  static Future<double> getHumidity() async {
    try {
      final row = await _db
          .select("humidity")
          .order("created_at", ascending: false)
          .limit(1)
          .single();

      // 2. Check your terminal for this print statement:
      print("DEBUG Humidity Row: $row");

      return (row["humidity"] as num).toDouble();
    } catch (e) {
      print("DEBUG Humidity Error: $e");
      rethrow;
    }
  }
}
