import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
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
        home: const Gate(),
      );
}

class Gate extends StatelessWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
  int index = 0;
  static const pages = <Widget>[
    DashboardScreen(),
    TransactionsScreen(),
    EntryScreen(),
    CategoriesScreen(),
    DebtsScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
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
