import 'package:dismed/services/supabase_service.dart';

class ConditionsService {
  static final _db = SupabaseService.client.from("medibot");

  /// Fetches the most recent temperature reading
  static Future<double> getTemperature() async {
    // Use ascending: false to get the newest record first
    final row = await _db
        .select("temperature")
        .order("created_at", ascending: false)
        .limit(1)
        .single();

    // Ensure we safely cast the dynamic value to a double
    return (row["temperature"] as num).toDouble();
  }

  /// Fetches the most recent humidity reading
  static Future<double> getHumidity() async {
    final row = await _db
        .select("humidity")
        .order("created_at", ascending: false)
        .limit(1)
        .single();

    return (row["humidity"] as num).toDouble();
  }
}

