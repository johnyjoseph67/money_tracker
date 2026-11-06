import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return ScreenList(
      title: 'Debts',
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
      ]),
      children: [
        Panel(
          color: color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payable ? 'Money you owe — closing pending' : 'Money owed to you — closing pending', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('AED ${aed(total)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty) Panel(child: EmptyNote(payable ? 'No payable balance or activity.' : 'No receivable balance or activity.')),
        for (final r in rows)
          _DebtCard(
            key: ValueKey('${payable ? 'p' : 'r'}:${r.key}'),
            row: r,
            color: color,
            pair: pair,
            entries: debtEntries(app.history, month, pair, r.key),
            addLabel: payable ? 'Borrowed' : 'Lent',
            paidLabel: payable ? 'Settled' : 'Received',
          ),
      ],
    );
  }
}

/// One person. Tap to expand and see each borrow/lend and every settlement/repayment with its date and amount.
class _DebtCard extends StatefulWidget {
  final DebtRow row;
  final Color color;
  final Pair pair;
  final List<Txn> entries;
  final String addLabel, paidLabel;
  const _DebtCard({super.key, required this.row, required this.color, required this.pair, required this.entries, required this.addLabel, required this.paidLabel});
  @override
  State<_DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<_DebtCard> {
  bool open = false;

  Widget _history() {
    final fmt = DateFormat('dd MMM yyyy');
    var balance = 0;
    final rows = <Widget>[];
    for (final t in widget.entries) {
      final isAdd = t.category == widget.pair.add;
      balance += isAdd ? t.amount : -t.amount;
      final c = isAdd ? widget.color : C.green;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(catIcon(t.category), size: 20, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAdd ? widget.addLabel : widget.paidLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
              Text(fmt.format(t.date), style: const TextStyle(fontSize: 12, color: C.slate)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('AED ${aed(t.amount)}', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
            Text('Pending ${aed(balance)}', style: const TextStyle(fontSize: 11, color: C.slate)),
          ]),
        ]),
      ));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text('${widget.addLabel} and ${widget.paidLabel.toLowerCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.slate)),
        ),
        ...rows,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final color = widget.color;
    final hasRepayments = widget.entries.any((t) => t.category == widget.pair.subtract);
    final hint = widget.pair == payablePair ? 'settlements' : 'repayments received';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: hasRepayments ? () => setState(() => open = !open) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(r.name.isEmpty ? '?' : r.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.navy))),
                  if (hasRepayments)
                    AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 28)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  _Cell('Opening', aed(r.opening)),
                  _Cell(widget.addLabel, aed(r.added)),
                  _Cell(widget.paidLabel, aed(r.paid)),
                  _Cell('Closing', aed(r.closing), color: color, bold: true),
                ]),
                if (hasRepayments)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(open ? 'Hide history' : 'Tap to see $hint', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  ),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open ? _history() : const SizedBox(width: double.infinity),
          ),
        ]),
      ),
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