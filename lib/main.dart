import 'package:dismed/core/app_theme.dart';
import 'package:dismed/core/auth_provider.dart';
import 'package:dismed/core/compartment_provider.dart';
import 'package:dismed/core/device_provider.dart';
import 'package:dismed/core/dispense_provider.dart';
import 'package:dismed/core/medication_provider.dart';
import 'package:dismed/core/notification_provider.dart';
import 'package:dismed/core/schedule_provider.dart';
import 'package:dismed/core/theme_provider.dart';
import 'package:dismed/screens/check_symptoms_screen.dart';
import 'package:dismed/screens/home.dart';
import 'package:dismed/screens/login_screen.dart';
import 'package:dismed/screens/splash_page.dart';
import 'package:dismed/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.get("SUPABASE_URL"),
    publishableKey: dotenv.get("SUPABASE_PUBLISHABLE_KEY"),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => CompartmentProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => DispenseProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Dismed",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: provider.mode,
      initialRoute: "/splash",
      routes: {
        "/splash": (context) => SplashPage(),
        "/register": (context) => CreateAccountScreen(),
        "/ai": (context) => CheckSymptoms(),

        "/home": (context) => Home(),
        "/login": (context) => LoginScreen(),
      },
    );
  }
}
