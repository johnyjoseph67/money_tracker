import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../logic.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  String month = currentMonth();
  int tab = 0; // 0 payable, 1 receivable

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final payable = tab == 0;
    final pair = payable ? payablePair : receivablePair;
    final color = payable ? C.orange : C.blue;
    final rows = debtSummary(app.history, month, pair);
    final total = rows.fold<int>(0, (a, r) => a + r.closing);
    final addLabel = payable ? 'Borrowed' : 'Lent';
    final paidLabel = payable ? 'Settled' : 'Received';
    return ScreenList(
      title: 'Debits',
      pinned: Column(children: [
        MonthBar(month: month, onChanged: (m) => setState(() => month = m)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Payable')),
              ButtonSegment(value: 1, label: Text('Receivable')),
            ],
            selected: {tab},
            onSelectionChanged: (s) => setState(() => tab = s.first),
          ),
        ),
          const SizedBox(height: 14),
        Panel(
          color: color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payable ? 'Money you owe — closing pending' : 'Money owed to you — closing pending', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('AED ${aed(total)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 14),
      ]),
      children: [
        
        if (rows.isEmpty) Panel(child: EmptyNote(payable ? 'No payable balance or activity.' : 'No receivable balance or activity.')),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Text(r.name.isEmpty ? '?' : r.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.navy))),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  _Cell('Opening', aed(r.opening)),
                  _Cell(addLabel, aed(r.added)),
                  _Cell(paidLabel, aed(r.paid)),
                  _Cell('Closing', aed(r.closing), color: color, bold: true),
                ]),
              ]),
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool bold;
  const _Cell(this.label, this.value, {this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: C.slate)),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? C.navy))),
        ]),
      );
}