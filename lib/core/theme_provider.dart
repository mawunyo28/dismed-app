import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;

    _mode = mode;
    notifyListeners();
  }

  void toggle() {
    setMode(_mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}
