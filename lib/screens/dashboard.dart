// screens/dashboard.dart
import 'package:dismed/core/condition_provider.dart';
import 'package:dismed/core/device_provider.dart';
import 'package:dismed/core/dispense_provider.dart';
import 'package:dismed/core/notification_provider.dart';
import 'package:dismed/core/schedule_provider.dart';
import 'package:dismed/core/auth_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final deviceProvider = context.read<DeviceProvider>();
    await deviceProvider.fetchDevices();

    final deviceId = deviceProvider.selectedDeviceId;
    if (deviceId == null) return;

    // Run everything in parallel to reduce load time
    await Future.wait([
      context.read<ScheduleProvider>().fetchTodaySchedules(deviceId),
      context.read<DispenseProvider>().fetchRecentLogs(deviceId),
      context.read<NotificationProvider>().fetchNotifications(unreadOnly: true),
      context.read<ConditionProvider>().fetchAllConditions(), // <-- Added this
    ]);

    // Start realtime subscriptions
    context.read<DispenseProvider>().subscribeRealtime(deviceId);
    context.read<NotificationProvider>().subscribeRealtime(context.read<AuthProvider>().user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final dispenseProvider = context.watch<DispenseProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final conditionProvider = context.watch<ConditionProvider>();

    final device = deviceProvider.selectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        actions: [
          if (notifProvider.unreadCount > 0)
            Stack(
              children: [
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.notifications_rounded)),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: context.colors.error, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${notifProvider.unreadCount}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Device status card
            if (device != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: device.isOnline ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: device.isOnline ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.memory_rounded,
                      color: device.isOnline ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.label!,
                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            device.isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.roboto(
                              textStyle: context.textTheme.bodySmall,
                              color: device.isOnline ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            Text(
              "Storage Conditions",
              style: GoogleFonts.roboto(
                textStyle: context.textTheme.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: EdgeInsetsGeometry.all(20),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,

                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: SizedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.5,
                        children: [
                          Text("Temperature", style: GoogleFonts.audiowide()),

                          Row(
                            children: [
                              Icon(Icons.thermostat),
                              SizedBox(width: 20),
                              Text(
                                "${conditionProvider.temperature == 0.0 ? "22" : conditionProvider.temperature.toString()} °C",
                                style: GoogleFonts.audiowide(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.5,
                        children: [
                          Text(
                            "Humidity",
                            style: GoogleFonts.audiowide(textStyle: context.textTheme.labelLarge),
                          ),

                          Row(
                            children: [
                              Icon(Icons.wind_power_rounded),
                              SizedBox(width: 20),
                              Text(
                                "${conditionProvider.humidity == 0.0 ? "78" : conditionProvider.humidity.toStringAsFixed(1)} %",
                                style: GoogleFonts.audiowide(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Today's schedules
            Text(
              "Today's Schedule",
              style: GoogleFonts.roboto(
                textStyle: context.textTheme.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (scheduleProvider.todaySchedules.isEmpty)
              _EmptyCard(
                icon: Icons.calendar_today_rounded,
                message: 'No doses scheduled for today',
              )
            else
              ...scheduleProvider.todaySchedules.map(
                (s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(Icons.medication_rounded, color: context.colors.primary),
                    title: Text(
                      s.dispenseTime.substring(0, 5),
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Slot ${s.compartmentId}',
                      style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                    ),
                    trailing: Icon(
                      s.active ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                      color: s.active ? context.colors.primary : context.colors.outlineVariant,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Recent dispense history
            Text(
              'Recent Activity',
              style: GoogleFonts.roboto(
                textStyle: context.textTheme.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (dispenseProvider.logs.isEmpty)
              _EmptyCard(icon: Icons.history_rounded, message: 'No dispense history yet')
            else
              ...dispenseProvider.logs
                  .take(10)
                  .map(
                    (log) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(log.status).withOpacity(0.15),
                          child: Icon(
                            _statusIcon(log.status),
                            color: _statusColor(log.status),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          log.status[0].toUpperCase() + log.status.substring(1),
                          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _formatTime(log.dispensedAt),
                          style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                        ),
                        trailing: Chip(
                          label: Text(log.triggeredBy, style: GoogleFonts.roboto(fontSize: 11)),
                          backgroundColor: context.colors.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            Text(
              "Health AI",
              style: GoogleFonts.roboto(
                textStyle: context.textTheme.titleMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: EdgeInsetsGeometry.all(20),

              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(21),
              ),

              child: ElevatedButton(
                autofocus: true,
                onPressed: () {
                  Navigator.pushNamed(context, "/ai");
                },
                child: Text(
                  "Run Ai Diagnostics",
                  style: GoogleFonts.audiowide(
                    textStyle: context.textTheme.titleMedium,
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_rounded;
      case 'missed':
        return Icons.close_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.colors.outlineVariant),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.roboto(
              textStyle: context.textTheme.bodyMedium,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
