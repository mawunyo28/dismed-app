import 'package:dismed/core/compartment_provider.dart';
import 'package:dismed/core/device_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Compartments extends StatefulWidget {
  const Compartments({super.key});

  @override
  State<Compartments> createState() => _CompartmentsState();
}

class _CompartmentsState extends State<Compartments> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deviceId = context.read<DeviceProvider>().selectedDeviceId;
      if (deviceId != null) {
        context.read<CompartmentProvider>().fetchCompartments(deviceId);
      }
    });
  }

  void _showEditSheet(String compartmentId) {
    final compProvider = context.read<CompartmentProvider>();
    final comp = compProvider.compartments.firstWhere((c) => c.id == compartmentId);

    final medController = TextEditingController(text: comp.medicationName ?? '');
    final dosageController = TextEditingController(text: comp.dosageMg?.toStringAsFixed(0) ?? '');
    final capacityController = TextEditingController(text: comp.capacity.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ctx.colors.primaryContainer,
                    child: Text(
                      '${comp.slot}',
                      style: GoogleFonts.roboto(
                        color: ctx.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Slot ${comp.slot}',
                    style: GoogleFonts.roboto(
                      textStyle: ctx.textTheme.titleLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Medication name
              _CompartmentField(
                controller: medController,
                hint: 'Medication name',
                icon: Icons.medication_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Dosage
              _CompartmentField(
                controller: dosageController,
                hint: 'Dosage (mg)',
                icon: Icons.scale_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              // Capacity
              _CompartmentField(
                controller: capacityController,
                hint: 'Capacity (max pills)',
                icon: Icons.inventory_2_rounded,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.colors.secondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final provider = context.read<CompartmentProvider>();

                  // Update medication name + dosage
                  await provider.updateMedication(
                    compartmentId,
                    medicationName: medController.text.trim(),
                    dosageMg: double.tryParse(dosageController.text.trim()),
                  );

                  // Update capacity if changed
                  final newCapacity = int.tryParse(capacityController.text.trim());
                  if (newCapacity != null && newCapacity != comp.capacity) {
                    await provider.updateCapacity(compartmentId, newCapacity);
                  }

                  if (mounted) Navigator.pop(ctx);
                },
                child: Text(
                  'Save Changes',
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

  void _confirmRefill(String compartmentId, int capacity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refill Compartment', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
          'Reset pill count to $capacity (full capacity)?',
          style: GoogleFonts.roboto(textStyle: ctx.textTheme.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.secondaryContainer),
            onPressed: () async {
              await context.read<CompartmentProvider>().refill(compartmentId);
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Refill', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _confirmManualDispense(String compartmentId, int slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manual Dispense', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
          'Trigger a manual dispense for slot $slot?',
          style: GoogleFonts.roboto(textStyle: ctx.textTheme.bodyMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.secondaryContainer),
            onPressed: () async {
              await context.read<CompartmentProvider>().manualDispense(compartmentId);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dispense requested for slot $slot', style: GoogleFonts.roboto()),
                    backgroundColor: ctx.colors.secondaryContainer,
                  ),
                );
              }
            },
            child: Text('Dispense', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compProvider = context.watch<CompartmentProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final device = deviceProvider.selectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          device != null ? device.label ?? 'Compartments' : 'Compartments',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Online/offline indicator
          if (device != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: device.isOnline ? context.colors.tertiary : context.colors.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    device.isOnline ? 'Online' : 'Offline',
                    style: GoogleFonts.roboto(
                      textStyle: context.textTheme.bodySmall,
                      color: device.isOnline ? context.colors.tertiary : context.colors.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: compProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : device == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_rounded, size: 64, color: context.colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No device selected',
                    style: GoogleFonts.roboto(textStyle: context.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Devices tab and select a device',
                    style: GoogleFonts.roboto(
                      textStyle: context.textTheme.bodySmall,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : compProvider.compartments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: context.colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No compartments found',
                    style: GoogleFonts.roboto(textStyle: context.textTheme.titleMedium),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => compProvider.fetchCompartments(deviceProvider.selectedDeviceId!),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: compProvider.compartments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final comp = compProvider.compartments[i];
                  return _CompartmentCard(
                    compartment: comp,
                    onEdit: () => _showEditSheet(comp.id),
                    onRefill: () => _confirmRefill(comp.id, comp.capacity),
                    onDispense: () => _confirmManualDispense(comp.id, comp.slot),
                  );
                },
              ),
            ),
    );
  }
}

// =============================================================================
// Compartment Card Widget
// =============================================================================

class _CompartmentCard extends StatelessWidget {
  final dynamic compartment;
  final VoidCallback onEdit;
  final VoidCallback onRefill;
  final VoidCallback onDispense;

  const _CompartmentCard({
    required this.compartment,
    required this.onEdit,
    required this.onRefill,
    required this.onDispense,
  });

  @override
  Widget build(BuildContext context) {
    final fillRatio = compartment.fillRatio as double;
    final isLowStock = compartment.isLowStock as bool;
    final isEmpty = compartment.pillCount == 0;

    // Progress bar color
    final Color barColor;
    if (isEmpty) {
      barColor = context.colors.error;
    } else if (isLowStock) {
      barColor = Colors.orange;
    } else {
      barColor = context.colors.tertiary;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isLowStock ? context.colors.errorContainer : context.colors.outlineVariant,
          width: isLowStock ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row — slot number + actions
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.colors.primaryContainer,
                  radius: 20,
                  child: Text(
                    '${compartment.slot}',
                    style: GoogleFonts.roboto(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compartment.medicationName ?? 'Empty slot',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          textStyle: context.textTheme.titleMedium,
                        ),
                      ),
                      if (compartment.dosageMg != null)
                        Text(
                          '${compartment.dosageMg!.toStringAsFixed(0)} mg',
                          style: GoogleFonts.roboto(
                            textStyle: context.textTheme.bodySmall,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: context.colors.primary),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stock bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock',
                            style: GoogleFonts.roboto(
                              textStyle: context.textTheme.labelMedium,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${compartment.pillCount} / ${compartment.capacity} pills',
                            style: GoogleFonts.roboto(
                              textStyle: context.textTheme.labelMedium,
                              fontWeight: FontWeight.w600,
                              color: isLowStock ? context.colors.error : context.colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: fillRatio.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: context.colors.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Low stock / empty warning
            if (isLowStock || isEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEmpty ? Icons.error_rounded : Icons.warning_amber_rounded,
                      size: 14,
                      color: context.colors.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEmpty ? 'Empty — refill needed' : 'Low stock — refill soon',
                      style: GoogleFonts.roboto(
                        textStyle: context.textTheme.labelSmall,
                        color: context.colors.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Refill
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: context.colors.outlineVariant),
                    ),
                    icon: Icon(Icons.refresh_rounded, size: 18, color: context.colors.primary),
                    label: Text(
                      'Refill',
                      style: GoogleFonts.roboto(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: onRefill,
                  ),
                ),
                const SizedBox(width: 10),
                // Manual dispense
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.secondaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: context.colors.onSecondaryContainer,
                    ),
                    label: Text(
                      'Dispense',
                      style: GoogleFonts.roboto(
                        color: context.colors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: isEmpty ? null : onDispense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Reusable text field for the edit sheet
// =============================================================================

class _CompartmentField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CompartmentField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.roboto(textStyle: context.textTheme.labelLarge),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colors.surface,
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w300),
        ),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
