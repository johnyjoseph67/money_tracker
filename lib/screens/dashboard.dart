import 'package:flutter/material.dart';
import 'package:money_tracker/settings.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../charts.dart';
import '../logic.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String month = currentMonth();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cash = cashSummary(app.history, app.salaries, month, app.initial);
    final pay = debtSummary(app.history, month, payablePair);
    final rec = debtSummary(app.history, month, receivablePair);
    final payPending = pay.fold<int>(0, (a, r) => a + r.closing);
    final recPending = rec.fold<int>(0, (a, r) => a + r.closing);
    final savings = cash.byCategory('Savings');

    return ScreenList(
      title: 'My Book',
      trailing: IconButton.filled(
        style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.navy),
        tooltip: 'Settings',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        icon: const Icon(Icons.settings_rounded),
      ),
      pinned: Column(
        children: [
          MonthBar(month: month, onChanged: (m) => setState(() => month = m)),
            const SizedBox(height: 18),
           Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(28)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Closing cash balance', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('AED ${aed(cash.closing)}', style: TextStyle(color: cash.closing < 0 ? const Color(0xFFFCA5A5) : Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 18),
            Row(children: [
              _Hero('Opening', aed(cash.opening)),
              const SizedBox(width: 24),
              _Hero('Salary', aed(cash.salary)),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(backgroundColor: C.mint, foregroundColor: C.navy),
                onPressed: () => showSalaryDialog(context, month),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Salary'),
              ),
            ]),
          ]),
        ),
        ],
      ),
      children: [
       
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: StatTile(label: 'Expenses / Savings', value: aed(cash.expenses), color: C.red, icon: Icons.trending_down_rounded)),
          const SizedBox(width: 12),
          Expanded(child: StatTile(label: 'Savings', value: aed(savings), color: C.teal, icon: Icons.savings_rounded)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: StatTile(label: 'Borrow + received', value: aed(cash.received), color: C.green, icon: Icons.south_west_rounded)),
          const SizedBox(width: 12),
          Expanded(child: StatTile(label: 'Lend + settled', value: aed(cash.paid), color: C.red, icon: Icons.north_east_rounded)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: StatTile(label: 'You owe (pending)', value: aed(payPending), color: C.orange, icon: Icons.account_balance_wallet_rounded)),
          const SizedBox(width: 12),
          Expanded(child: StatTile(label: 'Owed to you', value: aed(recPending), color: C.blue, icon: Icons.handshake_rounded)),
        ]),
        const SizedBox(height: 16),
        _Chart('Spending mix', SpendDonut(cash)),
        // _Chart(
        //   'Cash flow this month',
        //   MiniBars(
        //     labels: const ['Salary', 'In', 'Spent', 'Out', 'Cash'],
        //     values: [cash.salary / 100, cash.received / 100, cash.expenses / 100, cash.paid / 100, cash.closing / 100],
        //     colors: const [C.teal, C.green, C.red, C.orange, C.blue],
        //   ),
        // ),
        _Chart('12-month trend', TrendLines(history: app.history, salaries: app.salaries, initial: app.initial, month: month)),
        _Chart(
          'Pending balances',
          MiniBars(labels: const ['Payable', 'Receivable'], values: [payPending / 100, recPending / 100], colors: const [C.orange, C.blue]),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final String label, value;
  const _Hero(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ]);
}

class _Chart extends StatelessWidget {
  final String title;
  final Widget child;
  const _Chart(this.title, this.child);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.navy)),
            const SizedBox(height: 14),
            child,
          ]),
        ),
      );
}