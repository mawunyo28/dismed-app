import 'package:dismed/screens/dashboard.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.medication_rounded), label: "Medications"),
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
      body: [Dashboard()][currentPageIndex],
    );
  }
}
