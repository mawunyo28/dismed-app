// lib/screens/care_giver.dart
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule.dart';
import '../models/dispense_log.dart';

class CareGiver extends StatefulWidget {
  const CareGiver({super.key});

  @override
  State<CareGiver> createState() => _CareGiverState();
}

class _CareGiverState extends State<CareGiver> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _links = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  List<Schedule> _schedules = [];
  List<DispenseEvent> _events = [];
  bool _loading = true;
  bool _dataLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  Future<void> _fetchLinks() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Get accepted caregiver links where I am the caregiver
      final rows = await _supabase
          .from("caregiver_links")
          .select("id, patient_id, role, can_control, profiles!patient_id(full_name)")
          .eq("caregiver_id", userId)
          .eq("status", "accepted");

      setState(() {
        _links = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });

      // Auto-select first patient
      if (_links.isNotEmpty) {
        _selectPatient(
          _links.first["patient_id"],
          _links.first["profiles"]?["full_name"] ?? "Patient",
        );
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectPatient(String patientId, String name) async {
    setState(() {
      _selectedPatientId = patientId;
      _selectedPatientName = name;
      _dataLoading = true;
      _schedules = [];
      _events = [];
    });

    try {
      // Get patient's devices
      final devices = await _supabase.from("devices").select("id").eq("owner_id", patientId);

      if (devices.isEmpty) {
        setState(() => _dataLoading = false);
        return;
      }

      final deviceIds = devices.map((d) => d["id"]).toList();

      // Fetch schedules for all patient devices
      final scheduleRows = await _supabase
          .from("schedules")
          .select("*, compartments(slot, medication_name)")
          .inFilter("device_id", deviceIds)
          .eq("active", true)
          .order("dispense_time");

      // Fetch recent dispense events (last 7 days)
      final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final eventRows = await _supabase
          .from("dispense_events")
          .select()
          .inFilter("device_id", deviceIds)
          .gte("dispensed_at", since)
          .order("dispensed_at", ascending: false);

      setState(() {
        _schedules = scheduleRows.map((r) => Schedule.fromJson(r)).toList();
        _events = eventRows.map((r) => DispenseEvent.fromJson(r)).toList();
        _dataLoading = false;
      });
    } catch (e) {
      setState(() => _dataLoading = false);
    }
  }

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_links.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Caregiver", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 64, color: context.colors.outlineVariant),
              const SizedBox(height: 16),
              Text(
                "No patients linked",
                style: GoogleFonts.roboto(textStyle: context.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Text(
                "Ask a patient to link you\nas their caregiver in their app",
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  textStyle: context.textTheme.bodySmall,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Caregiver", style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Patient selector
          if (_links.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: context.colors.surfaceContainerHighest,
              child: DropdownButtonFormField<String>(
                value: _selectedPatientId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.person_rounded),
                  labelText: "Patient",
                ),
                items: _links
                    .map(
                      (l) => DropdownMenuItem(
                        value: l["patient_id"] as String,
                        child: Text(
                          l["profiles"]?["full_name"] ?? "Patient",
                          style: GoogleFonts.roboto(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final link = _links.firstWhere((l) => l["patient_id"] == id);
                  _selectPatient(id, link["profiles"]?["full_name"] ?? "Patient");
                },
              ),
            ),

          // Patient header
          if (_selectedPatientName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.colors.primaryContainer,
                    child: Icon(Icons.person_rounded, color: context.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatientName!,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          textStyle: context.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        "Read-only view",
                        style: GoogleFonts.roboto(
                          textStyle: context.textTheme.bodySmall,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _dataLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _selectPatient(_selectedPatientId!, _selectedPatientName!),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Schedules section
                        Text(
                          "Active Schedules",
                          style: GoogleFonts.roboto(
                            textStyle: context.textTheme.titleMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_schedules.isEmpty)
                          _EmptyCard(
                            icon: Icons.calendar_month_rounded,
                            message: "No active schedules",
                          )
                        else
                          ..._schedules.map(
                            (s) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          color: context.colors.primary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          s.dispenseTime.substring(0, 5),
                                          style: GoogleFonts.roboto(
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.primary,
                                            textStyle: context.textTheme.titleSmall,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "Slot ${1 ?? '?'}",
                                          style: GoogleFonts.roboto(
                                            textStyle: context.textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Day badges
                                    Row(
                                      children: List.generate(7, (d) {
                                        final active = s.daysOfWeek.contains(d);
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: active
                                                  ? context.colors.secondaryContainer
                                                  : context.colors.surface,
                                              border: Border.all(
                                                color: active
                                                    ? context.colors.secondary
                                                    : context.colors.outlineVariant,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _dayLabels[d],
                                                style: GoogleFonts.roboto(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: active
                                                      ? context.colors.onSecondaryContainer
                                                      : context.colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Dispense history section
                        Text(
                          "Recent Activity (7 days)",
                          style: GoogleFonts.roboto(
                            textStyle: context.textTheme.titleMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_events.isEmpty)
                          _EmptyCard(icon: Icons.history_rounded, message: "No dispense history")
                        else
                          ..._events
                              .take(20)
                              .map(
                                (e) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _statusColor(
                                        context,
                                        e.status,
                                      ).withOpacity(0.15),
                                      child: Icon(
                                        _statusIcon(e.status),
                                        color: _statusColor(context, e.status),
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      "${e.status[0].toUpperCase()}${e.status.substring(1)} — Slot ${e.slot ?? '?'}",
                                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      _formatTime(e.dispensedAt),
                                      style: GoogleFonts.roboto(
                                        textStyle: context.textTheme.bodySmall,
                                      ),
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        e.triggeredBy,
                                        style: GoogleFonts.roboto(fontSize: 11),
                                      ),
                                      backgroundColor: context.colors.surfaceContainerHighest,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'success':
        return context.colors.tertiary;
      case 'missed':
        return context.colors.error;
      default:
        return context.colors.primary;
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
    return '${diff.inDays}d ago at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

