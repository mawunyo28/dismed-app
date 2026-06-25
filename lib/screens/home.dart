import 'package:dismed/core/compartment_provider.dart';
import 'package:dismed/core/dispense_provider.dart';
import 'package:dismed/core/notification_provider.dart';
import 'package:dismed/screens/care_giver.dart';
import 'package:dismed/screens/compartment.dart';
import 'package:dismed/screens/dashboard.dart';
import 'package:dismed/screens/devices.dart';
import 'package:dismed/screens/medications.dart';
import 'package:dismed/screens/schedules.dart';
import 'package:dismed/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var currentPageIndex = 0;

  @override
  void dispose() {
    context.read<DispenseProvider>().unsubscribe();
    context.read<NotificationProvider>().unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          // NavigationDestination(icon: Icon(Icons.medication_rounded), label: "Med"),
          NavigationDestination(icon: Icon(Icons.pie_chart_rounded), label: "Compartment"),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: "Schedules"),
          NavigationDestination(icon: Icon(Icons.devices_rounded), label: "Device"),
          NavigationDestination(icon: Icon(Icons.health_and_safety_rounded), label: "Care giver"),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: "Settings"),
        ],

        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
      ),
      // Todo: Implement the other screens
      body: [
        Dashboard(),
        // Medications(),
        Compartments(),
        Schedules(),
        Devices(),
        CareGiver(),
        Settings(),
      ][currentPageIndex],
    );
  }
}
