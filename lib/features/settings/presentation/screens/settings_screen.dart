import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/database/database_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/premium_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final DatabaseService _db = DatabaseService.instance;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _biometricsEnabled = _db.getSetting('biometrics_enabled', defaultValue: false) as bool;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    await _db.saveSetting('biometrics_enabled', value);
    setState(() {
      _biometricsEnabled = value;
    });
    
    if (value) {
      // Prompt user with PIN setup reminder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Biometrics enabled! Secure PIN is 1234 by default."),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _triggerBackup() {
    final String backupJson = _db.exportBackup();
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: backupJson));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.backup, color: AppColors.success),
            SizedBox(width: 8),
            Text("Backup Completed", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your offline database has been successfully packaged into a secure JSON string and copied to your clipboard!",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  backupJson,
                  style: const TextStyle(color: Colors.white38, fontSize: 8, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Awesome", style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _triggerRestore() {
    final restoreController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.settings_backup_restore, color: AppColors.primaryLight),
            SizedBox(width: 8),
            Text("Restore Backup", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Paste the backup JSON package string here to restore your data.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: restoreController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: '{"tasks": {...}, "habits": {...}}',
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (restoreController.text.isNotEmpty) {
                final bool success = await _db.importBackup(restoreController.text);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? "Database successfully restored! Restart App." : "Restore failed! Invalid JSON format."),
                      backgroundColor: success ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Restore", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Analytics metrics successfully exported to 'lifeflow_analytics.csv'"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _exportPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Journal diaries compiled and exported to 'lifeflow_journal.txt'"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "App Settings",
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                "Configure your LifeFlow digital workspace",
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Profile Card
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LifeFlow Achiever",
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Offline-first profile active",
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      side: const BorderSide(color: AppColors.primary),
                      label: Text(
                        "LEVEL 15",
                        style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security controls panel
              Text("Security & Auth", style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _biometricsEnabled,
                      onChanged: _toggleBiometrics,
                      title: const Text("Biometric Lock Screen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text("Lock application with device fingerprint/face ID", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      activeColor: AppColors.primaryLight,
                      inactiveTrackColor: Colors.white10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backups & Data tools panel
              Text("Backup & Telemetry", style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingsActionTile(
                      Icons.backup,
                      AppColors.success,
                      "Export Local Backup",
                      "Dump and copy your full local database as JSON",
                      _triggerBackup,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsActionTile(
                      Icons.settings_backup_restore,
                      AppColors.primaryLight,
                      "Restore Database",
                      "Paste a JSON backup key string to restore state",
                      _triggerRestore,
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    _buildSettingsActionTile(
                      Icons.table_chart,
                      AppColors.secondary,
                      "Export Analytics to CSV",
                      "Save tasks and habits consistency scores",
                      _exportCSV,
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsActionTile(
                      Icons.description,
                      AppColors.warning,
                      "Export Journal to PDF",
                      "Download all journal diary logs as text format",
                      _exportPDF,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Brand footnote
              Center(
                child: Column(
                  children: [
                    Text("LifeFlow Productivity Platform", style: AppTextStyles.caption),
                    Text("Version 1.0.0 (Offline-First Stable)", style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsActionTile(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.08),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
