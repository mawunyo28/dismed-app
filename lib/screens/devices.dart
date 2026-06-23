import 'package:dismed/core/compartment_provider.dart';
import 'package:dismed/core/device_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Devices extends StatefulWidget {
  const Devices({super.key});

  @override
  State<Devices> createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().fetchDevices();
    });
  }

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();
    final keyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Device', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DeviceTextField(
                controller: nameController,
                hint: 'Device name',
                icon: Icons.devices_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              _DeviceTextField(
                controller: keyController,
                hint: 'Device key (from ESP32)',
                icon: Icons.key_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Enter device key' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.secondaryContainer),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await context.read<DeviceProvider>().addDevice(
                nameController.text.trim(),
                keyController.text.trim(),
              );
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Add', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Device', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: _DeviceTextField(
            controller: controller,
            hint: 'Device name',
            icon: Icons.edit_rounded,
            validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.secondaryContainer),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await context.read<DeviceProvider>().renameDevice(id, controller.text.trim());
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Device', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "$name"? This will remove all compartments, schedules and logs for this device.',
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
              await context.read<DeviceProvider>().deleteDevice(id);
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
    final deviceProvider = context.watch<DeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Devices', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        backgroundColor: context.colors.secondaryContainer,
        child: Icon(Icons.add_rounded, color: context.colors.onSurfaceVariant),
      ),
      body: deviceProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : deviceProvider.devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_rounded, size: 64, color: context.colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No devices yet',
                    style: GoogleFonts.roboto(textStyle: context.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your ESP32',
                    style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: deviceProvider.devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final device = deviceProvider.devices[i];
                final isSelected = deviceProvider.selectedDeviceId == device.id;

                return GestureDetector(
                  onTap: () {
                    deviceProvider.selectDevice(device.id);
                    context.read<CompartmentProvider>().fetchCompartments(device.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.secondaryContainer
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? context.colors.secondary
                            : context.colors.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: device.isOnline
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          Icons.memory_rounded,
                          color: device.isOnline ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      title: Text(
                        device.label!,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          textStyle: context.textTheme.titleMedium,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: device.isOnline ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                device.isOnline ? 'Online' : 'Offline',
                                style: GoogleFonts.roboto(
                                  textStyle: context.textTheme.bodySmall,
                                  color: device.isOnline ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          if (device.lastSeenAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Last seen: ${_formatLastSeen(device.lastSeenAt!)}',
                              style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall),
                            ),
                          ],
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text('Rename', style: GoogleFonts.roboto()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, size: 18, color: context.colors.error),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.roboto(color: context.colors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenameDialog(device.id, device.label!);
                          } else if (value == 'delete') {
                            _confirmDelete(device.id, device.label!);
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatLastSeen(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DeviceTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _DeviceTextField({
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: context.colors.onSurface),
        ),
      ),
    );
  }
}
