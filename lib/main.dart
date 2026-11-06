import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_drawer.dart';
import 'app_state.dart';
import 'loading_overlay.dart';
import 'screens/auth.dart';
import 'screens/categories.dart';
import 'screens/dashboard.dart';
import 'screens/debts.dart';
import 'screens/entry.dart';
import 'screens/transactions.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const MoneyApp()));
}

class MoneyApp extends StatelessWidget {
  const MoneyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'My Book',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // the loading overlay sits above every page, dialog and sheet
        builder: (context, child) => Stack(
          textDirection: TextDirection.ltr,
          fit: StackFit.expand,
          children: [child!, const Positioned.fill(child: LoadingOverlay())],
        ),
        navigatorObservers: [_UnfocusObserver()],
        home: const Gate(),
      );
}

/// When any dialog, sheet or page opens or closes, clear the text focus.
/// Otherwise Flutter gives focus back to the last field (e.g. the Add page amount) and the keyboard pops up.
class _UnfocusObserver extends NavigatorObserver {
  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _unfocus();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _unfocus();
}

/// Decides what to show: nothing yet, sign-in, loading, an error, or the app.
class Gate extends StatelessWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.ready) return const Scaffold();
    if (!app.signedIn) return const AuthScreen();
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
              TextButton(onPressed: app.logout, child: const Text('Log out')),
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

  static const titles = ['My Book', 'Activity', 'New entry', 'Categories', 'Debts'];
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

  void _hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _go(int i) async {
    _hideKeyboard();
    setState(() => index = i);
    _animating = true; // ignore page callbacks while animating, so the nav bar doesn't flicker
    await controller.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    _animating = false;
  }

  ButtonStyle get _chip => IconButton.styleFrom(backgroundColor: C.chip, foregroundColor: C.teal);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: C.navy,
          elevation: 3,
          scrolledUnderElevation: 3,
          shadowColor: const Color(0x330F172A),
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leadingWidth: 64,
          leading: Builder(
            builder: (ctx) => Center(
              child: IconButton(tooltip: 'Menu', style: _chip, icon: const Icon(Icons.menu_rounded), onPressed: () {
                  _hideKeyboard();
                  Scaffold.of(ctx).openDrawer();
                },
              ),
            ),
          ),
          titleSpacing: 4,
          title: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/icons/app_logo.png', width: 32, height: 32)),
            const SizedBox(width: 10),
            Text(titles[index], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.navy)),
          ]),
        ),
        drawer: const AppDrawer(),
        onDrawerChanged: (_) => _hideKeyboard(),
        body: PageView(
          controller: controller,
          onPageChanged: (i) {
            _hideKeyboard();
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