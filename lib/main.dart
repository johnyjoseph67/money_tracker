import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'loading_overlay.dart';
import 'screens/categories.dart';
import 'screens/dashboard.dart';
import 'screens/debts.dart';
import 'screens/entry.dart';
import 'screens/transactions.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const MoneyApp()));
}

class MoneyApp extends StatelessWidget {
  const MoneyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'My Book',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // the overlay sits above every page, dialog and sheet
        builder: (context, child) => Stack(
          textDirection: TextDirection.ltr,
          fit: StackFit.expand,
          children: [child!, const Positioned.fill(child: LoadingOverlay())],
        ),
        home: const Gate(),
      );
}

class Gate extends StatelessWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) return const Scaffold(); // the centre overlay shows the progress indicator
    if (app.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: C.red),
              const SizedBox(height: 16),
              Text(app.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: app.load, child: const Text('Try again')),
            ]),
          ),
        ),
      );
    }
    return const Shell();
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final controller = PageController();
  int index = 0;
  bool _animating = false;

  static const pages = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    EntryScreen(),
    CategoriesScreen(),
    DebtsScreen(),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _go(int i) async {
    setState(() => index = i);
    _animating = true; // ignore page callbacks while animating, so the nav bar doesn't flicker
    await controller.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    _animating = false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PageView(
          controller: controller,
          onPageChanged: (i) {
            if (!_animating) setState(() => index = i);
          },
          children: [for (final p in pages) KeepAlivePage(child: p)],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _go,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Activity'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Add'),
            NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded), selectedIcon: Icon(Icons.pie_chart_rounded), label: 'Categories'),
            NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), selectedIcon: Icon(Icons.swap_horiz_rounded), label: 'Debts'),
          ],
        ),
      );
}

/// Keeps each tab alive while swiping, so typed text and the chosen month are not lost.
class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});
  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
} 