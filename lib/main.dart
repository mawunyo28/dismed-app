import 'package:dismed/core/app_theme.dart';
import 'package:dismed/core/theme_provider.dart';
import 'package:dismed/screens/home.dart';
import 'package:dismed/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:  "https://imjwkzsctggnyxvhunza.supabase.co",
    publishableKey: "sb_publishable_bzL6dpvb4jLl5WB_ncnwrQ_jiYfcY_a"
  );
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
      "/home": (context) => Home(),
    },
      
    );
  }
}
