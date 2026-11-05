import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController ctrl;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final init = context.read<AppState>().initial;
    ctrl = TextEditingController(text: init == 0 ? '' : (init / 100).toStringAsFixed(2));
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _saveInitial() async {
    final raw = ctrl.text.replaceAll(',', '').trim();
    final v = double.tryParse(raw.isEmpty ? '0' : raw);
    if (v == null) return toast(context, 'Enter initial cash (zero is allowed).', error: true);
    setState(() => busy = true);
    try {
      await context.read<AppState>().setInitial(v);
      if (mounted) toast(context, 'Initial cash saved');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _sync() async {
    setState(() => busy = true);
    try {
      await context.read<AppState>().refresh();
      if (mounted) toast(context, 'Synced with Google Sheet');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _turnOffBiometrics() async {
    await context.read<AppState>().disableBiometricLogin();
    if (mounted) toast(context, 'Fingerprint / face sign-in turned off');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final synced = app.lastSync == null ? 'Not synced yet' : 'Last synced ${DateFormat('dd MMM yyyy, HH:mm').format(app.lastSync!)}';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Initial cash balance', style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
            const SizedBox(height: 4),
            const Text('Saved to Sheet 2, cell L2.', style: TextStyle(fontSize: 12, color: C.slate)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: deco('Amount (AED)')),
            const SizedBox(height: 12),
            FilledButton(onPressed: busy ? null : _saveInitial, child: const Text('Save')),
          ]),
        ),
        if (app.savedCredentials != null) ...[
          const SizedBox(height: 16),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fingerprint / face sign-in', style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
              const SizedBox(height: 6),
              const Text("Turned on. Your password is kept in the phone's secure storage and the sign-in page is never pre-filled.", style: TextStyle(fontSize: 12, color: C.slate)),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: busy ? null : _turnOffBiometrics, icon: const Icon(Icons.fingerprint_rounded), label: const Text('Turn off')),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Google Sheet', style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
            const SizedBox(height: 6),
            const Text('Entries are read from and saved to your sheet "2 Transactions". Reports in the sheet refresh automatically.', style: TextStyle(fontSize: 12, color: C.slate)),
            const SizedBox(height: 6),
            Text(synced, style: const TextStyle(fontSize: 12, color: C.slate)),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(onPressed: busy ? null : _sync, icon: const Icon(Icons.sync_rounded), label: const Text('Sync now')),
          ]),
        ),
      ]),
    );
  }
}