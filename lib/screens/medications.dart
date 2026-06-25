import 'package:dismed/core/compartment_provider.dart';
import 'package:dismed/core/device_provider.dart';
import 'package:dismed/core/medication_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Medications extends StatefulWidget {
  const Medications({super.key});

  @override
  State<Medications> createState() => _MedicationsState();
}

class _MedicationsState extends State<Medications> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceId = context.read<DeviceProvider>().selectedDeviceId;
      context.read<MedicationProvider>().fetchMedications();
      if (deviceId != null) {
        context.read<CompartmentProvider>().fetchCompartments(deviceId);
      }
    });
  }

  void _showMedicationSheet({String? editId}) {
    final medProvider = context.read<MedicationProvider>();
    final compartments = context.read<CompartmentProvider>().compartments;

    // pre-fill if editing
    final existing = editId != null
        ? medProvider.medications.firstWhere((m) => m.id == editId)
        : null;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final dosageController = TextEditingController(text: existing?.dosage ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String? selectedCompartmentId = existing?.compartmentId ?? compartments.firstOrNull?.id;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  editId == null ? 'Add Medication' : 'Edit Medication',
                  style: GoogleFonts.roboto(
                    textStyle: ctx.textTheme.titleLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _SheetTextField(
                  controller: nameController,
                  hint: 'Medication name',
                  icon: Icons.medication_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _SheetTextField(
                  controller: dosageController,
                  hint: 'Dosage (e.g. 1 tablet)',
                  icon: Icons.scale_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _SheetTextField(
                  controller: notesController,
                  hint: 'Notes (optional)',
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(height: 14),
                // Compartment picker
                DropdownButtonFormField<String>(
                  initialValue: selectedCompartmentId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ctx.colors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: const Icon(Icons.inbox_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    labelText: 'Compartment',
                  ),
                  items: compartments
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            'Slot ${c.slot} — ${c.medicationName}',
                            style: GoogleFonts.roboto(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setSheetState(() => selectedCompartmentId = v),
                  validator: (v) => v == null ? 'Select a compartment' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctx.colors.secondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (editId == null) {
                      await context.read<MedicationProvider>().addMedication(
                        compartmentId: selectedCompartmentId!,
                        name: nameController.text.trim(),
                        dosage: dosageController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                    } else {
                      await context.read<MedicationProvider>().updateMedication(
                        editId,
                        name: nameController.text.trim(),
                        dosage: dosageController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                    }
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Text(
                    editId == null ? 'Add Medication' : 'Save Changes',
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
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Medication', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "$name"? Associated schedules will also be removed.',
          style: GoogleFonts.roboto(textStyle: ctx.textTheme.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.errorContainer),
            onPressed: () async {
              await context.read<MedicationProvider>().deleteMedication(id);
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Delete', style: GoogleFonts.roboto(color: ctx.colors.onError)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medProvider = context.watch<MedicationProvider>();
    final compartments = context.watch<CompartmentProvider>().compartments;

    // group by slot number
    final grouped = <int, List<dynamic>>{1: [], 2: [], 3: []};
    for (final med in medProvider.medications) {
      final comp = compartments.where((c) => c.id == med.compartmentId).firstOrNull;
      final slot = comp?.slot ?? 0;
      grouped[slot] ??= [];
      grouped[slot]!.add(med);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Medications', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMedicationSheet(),
        backgroundColor: context.colors.secondaryContainer,
        child: Icon(Icons.add_rounded, color: context.colors.onSurfaceVariant),
      ),
      body: medProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : medProvider.medications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_rounded, size: 64, color: context.colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No medications yet',
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final slot in [1, 2, 3])
                  if ((grouped[slot] ?? []).isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Slot $slot — ${compartments.firstWhere((c) => c.slot == slot, orElse: () => compartments.first).medicationName}',
                        style: GoogleFonts.roboto(
                          textStyle: context.textTheme.labelLarge,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                    ...grouped[slot]!.map(
                      (med) => Dismissible(
                        key: Key(med.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          _confirmDelete(med.id, med.name);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: context.colors.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.delete_rounded, color: context.colors.onError),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: context.colors.primaryContainer,
                              child: Icon(Icons.medication_rounded, color: context.colors.primary),
                            ),
                            title: Text(
                              med.name,
                              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              med.dosage,
                              style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () => _showMedicationSheet(editId: med.id),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
              ],
            ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _SheetTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.roboto(textStyle: context.textTheme.labelLarge),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w300),
        ),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
