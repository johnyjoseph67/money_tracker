import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../app_state.dart';
import '../biometric_service.dart';
import '../theme.dart';
import '../widgets.dart';

OutlineInputBorder _border(Color c, double w) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));

InputDecoration _deco(String label, IconData icon, {Widget? suffix, String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: C.slate),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: _border(const Color(0xFFE2E8F0), 1.5),
      enabledBorder: _border(const Color(0xFFE2E8F0), 1.5),
      focusedBorder: _border(C.teal, 2),
    );

ButtonStyle _primary() => FilledButton.styleFrom(
      backgroundColor: C.teal,
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

/// Switches between the login and registration pages.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = false;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: register
            ? RegisterPage(key: const ValueKey('register'), onSwitch: () => setState(() => register = false))
            : LoginPage(key: const ValueKey('login'), onSwitch: () => setState(() => register = true)),
      );
}

// ------------------------------------------------------------------ login
class LoginPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginPage({super.key, required this.onSwitch});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  final url = TextEditingController();
  final token = TextEditingController();
  bool hide = true;
  bool remember = false;
  bool bioAvailable = false;
  final bioService = BiometricService();
  late bool showConn;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final acc = app.account;
    showConn = acc == null; // a new device must enter the connection once
    url.text = acc?.url ?? '';
    token.text = acc?.token ?? '';
    final saved = app.savedCredentials; // filled in when 'Remember password' was ticked
    if (saved != null) {
      user.text = saved.username;
      pass.text = saved.password;
      remember = true;
    }
    bioService.available().then((v) {
      if (mounted) setState(() => bioAvailable = v);
    });
  }

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    url.dispose();
    token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) {
      return toast(context, 'Enter your username and password.', error: true);
    }
    try {
      await context.read<AppState>().login(
            username: user.text.trim(),
            password: pass.text,
            remember: remember,
            url: showConn ? url.text : null,
            token: showConn ? token.text : null,
          );
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  /// Fingerprint / face, then sign in with the password saved by "Remember password".
  Future<void> _signInWithBiometrics() async {
    final app = context.read<AppState>();
    final saved = app.savedCredentials;
    if (saved == null) return;
    final problem = await bioService.authenticate(); // null = success, otherwise the reason
    if (problem != null) {
      if (mounted) toast(context, problem, error: true);
      return;
    }
    try {
      await app.login(
        username: saved.username,
        password: saved.password,
        remember: true,
        url: showConn ? url.text : null,
        token: showConn ? token.text : null,
      );
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.paper,
        body: SingleChildScrollView(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 48, 24, 72),
              decoration: const BoxDecoration(color: C.navy, borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))),
              child: Column(children: [
                ClipRRect(borderRadius: BorderRadius.circular(26), child: Image.asset('assets/icons/app_logo.png', width: 88, height: 88)),
                const SizedBox(height: 16),
                const Text('My Book', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Your money, neatly in one book', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14)),
              ]),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Panel(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Welcome back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.navy)),
                    const Text('Sign in to continue', style: TextStyle(color: C.slate)),
                    const SizedBox(height: 20),
                    TextField(controller: user, autocorrect: false, textInputAction: TextInputAction.next, decoration: _deco('Username', Icons.person_outline_rounded)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: pass,
                      obscureText: hide,
                      onSubmitted: (_) => _submit(),
                      decoration: _deco('Password', Icons.lock_outline_rounded,
                          suffix: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                    ),
                    CheckboxListTile(
                      value: remember,
                      onChanged: (v) => setState(() => remember = v ?? false),
                      title: const Text('Remember password', style: TextStyle(fontSize: 14, color: C.navy)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: C.teal,
                    ),
                    if (bioAvailable && context.read<AppState>().savedCredentials == null)
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 4),
                        child: Text('Tick Remember password once to turn on fingerprint / face sign-in.', style: TextStyle(fontSize: 12, color: C.slate)),
                      ),
                    if (showConn) ...[
                      const SizedBox(height: 8),
                      const Text('Google Sheet connection', style: TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
                      const SizedBox(height: 10),
                      TextField(controller: url, autocorrect: false, keyboardType: TextInputType.url, decoration: _deco('Web app URL', Icons.link_rounded)),
                      const SizedBox(height: 14),
                      TextField(controller: token, obscureText: true, autocorrect: false, decoration: _deco('API token', Icons.vpn_key_outlined)),
                      const SizedBox(height: 8),
                    ] else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(onPressed: () => setState(() => showConn = true), icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Change connection')),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(style: _primary(), onPressed: _submit, child: const Text('Sign in')),
                    if (bioAvailable && context.read<AppState>().savedCredentials != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C.teal,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: C.teal, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _signInWithBiometrics,
                        icon: const Icon(Icons.fingerprint_rounded, size: 26),
                        label: const Text('Sign in with fingerprint / face'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: widget.onSwitch,
                        child: const Text.rich(TextSpan(text: 'New here? ', style: TextStyle(color: C.slate), children: [
                          TextSpan(text: 'Create account', style: TextStyle(color: C.teal, fontWeight: FontWeight.w700)),
                        ])),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 24), child: Text('Version $appVersion', style: TextStyle(fontSize: 12, color: C.slate))),
          ]),
        ),
      );
}

// --------------------------------------------------------------- register
class RegisterPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const RegisterPage({super.key, required this.onSwitch});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();
  final url = TextEditingController();
  final token = TextEditingController();
  bool hide = true;

  @override
  void dispose() {
    for (final c in [name, user, pass, confirm, url, token]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _test() async {
    try {
      await context.read<AppState>().testConnection(url.text, token.text);
      if (mounted) toast(context, 'Connection successful');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  Future<void> _create() async {
    String? err;
    if (name.text.trim().length < 2) {
      err = 'Enter your full name.';
    } else if (!RegExp(r'^[A-Za-z0-9_.-]{3,30}$').hasMatch(user.text.trim())) {
      err = 'Username must be 3-30 letters, numbers, dot, dash or underscore.';
    } else if (pass.text.length < 6) {
      err = 'Password must be at least 6 characters.';
    } else if (pass.text != confirm.text) {
      err = 'Passwords do not match.';
    } else if (url.text.trim().isEmpty || token.text.trim().isEmpty) {
      err = 'Enter the Web app URL and API token.';
    }
    if (err != null) return toast(context, err, error: true);
    try {
      await context.read<AppState>().register(name: name.text.trim(), username: user.text.trim(), password: pass.text, url: url.text, token: token.text);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  Widget _step(int n, String title) => Row(children: [
        CircleAvatar(radius: 14, backgroundColor: C.chip, child: Text('$n', style: const TextStyle(color: C.teal, fontWeight: FontWeight.w700, fontSize: 13))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.paper,
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
            Row(children: [
              IconButton(
                tooltip: 'Back to sign in',
                style: IconButton.styleFrom(backgroundColor: C.chip, foregroundColor: C.teal),
                onPressed: widget.onSwitch,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 12),
              const Text('Create account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.navy)),
            ]),
            const SizedBox(height: 16),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _step(1, 'Your details'),
                const SizedBox(height: 16),
                TextField(controller: name, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: _deco('Full name', Icons.badge_outlined)),
                const SizedBox(height: 14),
                TextField(controller: user, autocorrect: false, textInputAction: TextInputAction.next, decoration: _deco('Username', Icons.person_outline_rounded)),
                const SizedBox(height: 14),
                TextField(
                  controller: pass,
                  obscureText: hide,
                  decoration: _deco('Password', Icons.lock_outline_rounded,
                      hint: 'At least 6 characters',
                      suffix: IconButton(onPressed: () => setState(() => hide = !hide), icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                ),
                const SizedBox(height: 14),
                TextField(controller: confirm, obscureText: hide, decoration: _deco('Confirm password', Icons.lock_outline_rounded)),
              ]),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _step(2, 'Google Sheet connection'),
                const SizedBox(height: 6),
                const Text('From Apps Script: Deploy > Web app. Saved on this device only.', style: TextStyle(fontSize: 12, color: C.slate)),
                const SizedBox(height: 14),
                TextField(controller: url, autocorrect: false, keyboardType: TextInputType.url, decoration: _deco('Web app URL', Icons.link_rounded)),
                const SizedBox(height: 14),
                TextField(controller: token, obscureText: true, autocorrect: false, decoration: _deco('API token', Icons.vpn_key_outlined)),
                const SizedBox(height: 14),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: C.chip,
                    foregroundColor: C.teal,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: _test,
                  child: const Text('Test connection', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            FilledButton(style: _primary(), onPressed: _create, child: const Text('Create account')),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.onSwitch,
                child: const Text.rich(TextSpan(text: 'Already registered? ', style: TextStyle(color: C.slate), children: [
                  TextSpan(text: 'Sign in', style: TextStyle(color: C.teal, fontWeight: FontWeight.w700)),
                ])),
              ),
            ),
          ]),
        ),
      );
}