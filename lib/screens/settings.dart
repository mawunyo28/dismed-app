import 'package:dismed/core/auth_provider.dart';
import 'package:dismed/core/theme_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.account_circle_rounded,
            title: auth.user?.email ?? 'User',
            subtitle: 'Signed in',
            trailing: const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Appearance section
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Theme',
            subtitle: _themeLabel(themeProvider.mode),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.mode,
              underline: const SizedBox.shrink(),
              style: GoogleFonts.roboto(
                textStyle: context.textTheme.bodyMedium,
                color: context.colors.onSurface,
              ),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) themeProvider.setMode(mode);
              },
            ),
          ),

          const SizedBox(height: 16),

          // About section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0',
            trailing: const SizedBox.shrink(),
          ),
          _SettingsTile(
            icon: Icons.medical_services_rounded,
            title: 'Dismed',
            subtitle: 'Smart pill dispenser',
            trailing: const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Sign out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.errorContainer,
                foregroundColor: context.colors.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'Sign Out',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Sign Out', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                    content: Text(
                      'Are you sure you want to sign out?',
                      style: GoogleFonts.roboto(textStyle: ctx.textTheme.bodyMedium),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.roboto(color: ctx.colors.onSurfaceVariant),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: ctx.colors.errorContainer),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.roboto(color: ctx.colors.onError),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await context.read<AuthProvider>().signOut();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          textStyle: context.textTheme.labelLarge,
          fontWeight: FontWeight.bold,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: context.colors.primaryContainer,
          child: Icon(icon, color: context.colors.primary),
        ),
        title: Text(title, style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.roboto(textStyle: context.textTheme.bodySmall)),
        trailing: trailing,
      ),
    );
  }
}

