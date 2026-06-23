import 'package:dismed/core/device_provider.dart';
import 'package:dismed/core/medication_provider.dart';
import 'package:dismed/core/schedule_provider.dart';
import 'package:dismed/core/compartment_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Schedules extends StatefulWidget {
  const Schedules({super.key});

  @override
  State<Schedules> createState() => _SchedulesState();
}

class _SchedulesState extends State<Schedules> {
  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().fetchSchedules();
      context.read<MedicationProvider>().fetchMedications();
    });
  }

  void _showAddScheduleSheet() {
    final medications = context.read<MedicationProvider>().medications;
    final compartments = context.read<CompartmentProvider>().compartments;
    final deviceId = context.read<DeviceProvider>().selectedDeviceId;

    if (deviceId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a device first from the Device tab')));
      return;
    }

    String? selectedMedId = medications.firstOrNull?.id;
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mon–Fri default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Schedule',
                style: GoogleFonts.roboto(
                  textStyle: ctx.textTheme.titleLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Medication picker
              DropdownButtonFormField<String>(
                value: selectedMedId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ctx.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: const Icon(Icons.medication_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  labelText: 'Medication',
                ),
                items: medications
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.name, style: GoogleFonts.roboto()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedMedId = v),
              ),
              const SizedBox(height: 14),

              // Time picker
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (picked != null) {
                    setSheetState(() => selectedTime = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ctx.colors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: const Icon(Icons.access_time_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    labelText: 'Time',
                  ),
                  child: Text(
                    selectedTime.format(ctx),
                    style: GoogleFonts.roboto(textStyle: ctx.textTheme.labelLarge),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Day picker
              Text(
                'Days',
                style: GoogleFonts.roboto(
                  textStyle: ctx.textTheme.labelMedium,
                  color: ctx.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final selected = selectedDays.contains(i);
                  return GestureDetector(
                    onTap: () => setSheetState(() {
                      selected ? selectedDays.remove(i) : selectedDays.add(i);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? ctx.colors.secondaryContainer : ctx.colors.surface,
                        border: Border.all(
                          color: selected ? ctx.colors.secondary : ctx.colors.outlineVariant,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? ctx.colors.onSecondaryContainer
                                : ctx.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.colors.secondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  if (selectedMedId == null || selectedDays.isEmpty) return;
                  final med = medications.firstWhere((m) => m.id == selectedMedId);
                  final timeStr =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                  await context.read<ScheduleProvider>().addSchedule(
                    medicationId: selectedMedId!,
                    compartmentId: med.compartmentId,
                    deviceId: deviceId,
                    scheduledTime: timeStr,
                    daysOfWeek: selectedDays..sort(),
                  );
                  if (mounted) Navigator.pop(ctx);
                },
                child: Text(
                  'Add Schedule',
                  style: GoogleFonts.roboto(
                    color: ctx.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final medications = context.watch<MedicationProvider>().medications;

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedules', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleSheet,
        backgroundColor: context.colors.secondaryContainer,
        child: Icon(Icons.add_rounded, color: context.colors.onSurfaceVariant),
      ),
      body: scheduleProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : scheduleProvider.schedules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 64,
                    color: context.colors.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No schedules yet',
                    style: GoogleFonts.roboto(textStyle: context.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add one',
                    style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: scheduleProvider.schedules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = scheduleProvider.schedules[i];
                final medName = medications
                    .firstWhere((m) => m.id == s.medicationId, orElse: () => medications.first)
                    .name;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              medName,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                textStyle: context.textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              value: s.isActive,
                              onChanged: (v) =>
                                  context.read<ScheduleProvider>().toggleActive(s.id, v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: context.colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.scheduledTime.substring(0, 5),
                              style: GoogleFonts.roboto(
                                textStyle: context.textTheme.bodyMedium,
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Day badges
                        Row(
                          children: List.generate(7, (d) {
                            final active = s.daysOfWeek.contains(d);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 30,
                                height: 30,
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
                                      fontSize: 11,
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: context.colors.error),
                            onPressed: () => context.read<ScheduleProvider>().deleteSchedule(s.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

