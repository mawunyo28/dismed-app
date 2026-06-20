import 'package:dismed/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void switchTheme(BuildContext context, ThemeMode mode) {
  context.read<ThemeProvider>().setMode(mode);
}

void toggleTheme(BuildContext context) {
  context.read<ThemeProvider>().toggle();
}
