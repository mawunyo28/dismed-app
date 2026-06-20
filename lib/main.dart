import 'package:dismed/core/app_theme.dart';
import 'package:dismed/core/theme_provider.dart';
import 'package:dismed/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: "Dismed",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: provider.mode,
      initialRoute: "/",
      routes: {
      "/": (context) => LoginScreen(),
      "/login": (context)=> LoginScreen(),
    },
      
    );
  }
}
