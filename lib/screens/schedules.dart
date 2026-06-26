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
      final deviceId = context.read<DeviceProvider>().selectedDeviceId;
      if (deviceId == null) return;
      context.read<ScheduleProvider>().fetchSchedules(deviceId);
      context.read<MedicationProvider>().fetchMedications();
    });
  }

  void _showAddScheduleSheet() {
    final compartments = context.read<CompartmentProvider>().compartments;
    final deviceId = context.read<DeviceProvider>().selectedDeviceId;

    double _pillsPerDose = 2.0;

    if (deviceId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a device first from the Devices tab')));
      return;
    }

    // guard — don't open sheet if no compartments loaded
    if (compartments.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No compartments found for this device')));
      return;
    }
    String? selectedCompId = compartments.firstOrNull?.id;

    // String? selectedMedId = medications.firstOrNull?.id;
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
                initialValue: selectedCompId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ctx.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: const Icon(Icons.medication_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  labelText: 'Medication',
                ),
                items: compartments
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.medicationName ?? "${m.slot}", style: GoogleFonts.roboto()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedCompId = v),
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

              // pill selected
              Slider(
                value: _pillsPerDose,
                max: 10.0,
                divisions: 9,
                min: 1,
                label: _pillsPerDose.toString(),
                onChanged: (double value) {
                  setSheetState(() {
                    _pillsPerDose = value;
                  });
                },
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
                  if (selectedCompId == null || selectedDays.isEmpty) return;
                  final comp = compartments.firstWhere((c) => c.id == selectedCompId);
                  final timeStr =
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
                  await context.read<ScheduleProvider>().addSchedule(
                    compartmentId: comp.id,
                    deviceId: deviceId,
                    daysOfWeek: selectedDays..sort(),
                    dispenseTime: timeStr,
                    pillsPerDose: _pillsPerDose.toInt(),
                    // Todo: Pills per dispense
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
    final compartment = context.watch<CompartmentProvider>().compartments;

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
                final compName = compartment
                    .where((c) => c.id == s.compartmentId).firstOrNull?.medicationName;

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
                              compName ?? "Unknown",
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w600,
                                textStyle: context.textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              value: s.active,
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
                              s.dispenseTime.substring(0, 5),
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
