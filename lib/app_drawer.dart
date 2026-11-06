import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/settings.dart';
import 'package:provider/provider.dart';

import 'app_info.dart';
import 'app_state.dart';
import 'theme.dart';

/// Side sheet: profile, Sync, Settings, Log out and the version number.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _snack(ScaffoldMessengerState m, String text, {bool error = false}) {
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? C.red : C.teal, behavior: SnackBarBehavior.floating));
  }

  Future<void> _sync(BuildContext context) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // close the side sheet, then show the loading indicator
    try {
      await app.refresh();
      _snack(messenger, 'Synced with Google Sheet');
    } catch (e) {
      _snack(messenger, errText(e), error: true);
    }
  }

  void _openSettings(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _logout(BuildContext context) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: C.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    if (context.mounted) Navigator.pop(context); // close the side sheet
    await app.logout();
  }

  Widget _tile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: C.chip, borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: C.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
        subtitle: subtitle == null ? null : Text(subtitle, style: const TextStyle(fontSize: 12, color: C.slate)),
        trailing: const Icon(Icons.chevron_right_rounded, color: C.slate),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final top = MediaQuery.of(context).padding.top;
    final synced = app.lastSync == null ? 'Not synced yet' : 'Last synced ${DateFormat('dd MMM, HH:mm').format(app.lastSync!)}';
    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: Column(children: [
        Container(
          width: double.infinity,
          color: C.navy,
          padding: EdgeInsets.fromLTRB(24, top + 32, 24, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(shape: BoxShape.circle, color: C.chip, border: Border.all(color: C.mint, width: 3)),
              child: const Icon(Icons.person_rounded, size: 52, color: C.teal),
            ),
            const SizedBox(height: 14),
            Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('@${user?.username ?? ''}', style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 14)),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(top: 12), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                const Text('Connected to Google Sheet', style: TextStyle(fontSize: 13, color: C.slate)),
              ]),
            ),
            _tile(icon: Icons.sync_rounded, title: 'Sync now', subtitle: synced, onTap: () => _sync(context)),
            _tile(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'Initial cash, sign-in options', onTap: () => _openSettings(context)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    foregroundColor: C.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Version $appVersion', style: TextStyle(fontSize: 12, color: C.slate)),
            ]),
          ),
        ),
      ]),
    );
  }
}