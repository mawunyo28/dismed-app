import 'package:flutter/material.dart';
import '../services/conditions_service.dart';

class ConditionProvider extends ChangeNotifier {
  double _temperature = 0.0;
  double _humidity = 0.0;
  String? _error; // Typed explicitly instead of var/null
  bool _isLoading = false;

  // Getters
  double get temperature => _temperature;
  double get humidity => _humidity;
  String? get error => _error;
  bool get isLoading => _isLoading;

  /// Fetches both temperature and humidity sequentially or together
  Future<void> fetchAllConditions() async {
    _setLoading(true);
    _error = null;

    try {
      // Running them in parallel speeds up the network request
      final results = await Future.wait([
        ConditionsService.getTemperature(),
        ConditionsService.getHumidity(),
      ]);

      _temperature = results[0];
      _humidity = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false); // This calls notifyListeners()
    }
  }

  Future<void> fetchTemperatureCondition() async {
    _error = null;
    try {
      _temperature = await ConditionsService.getTemperature();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchHumidityCondition() async {
    _error = null;
    try {
      _humidity = await ConditionsService.getHumidity();
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

