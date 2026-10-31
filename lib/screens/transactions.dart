import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String month = currentMonth();

  Future<bool> _confirmDelete(Txn t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('${t.category} · AED ${aed(t.amount)} on ${DateFormat('dd MMM yyyy').format(t.date)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: C.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return false;
    try {
      await context.read<AppState>().deleteTransaction(t);
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
    return false; // the list rebuilds from state
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rows = app.history.where((t) => t.month == month).toList()
      ..sort((a, b) {
        final c = b.day.compareTo(a.day);
        return c != 0 ? c : b.savedAt.compareTo(a.savedAt);
      });
    return ScreenList(
      title: 'Transactions',
      pinned: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonthBar(month: month, onChanged: (m) => setState(() => month = m)),
            const SizedBox(height: 8),
           Text('${rows.length} ${rows.length == 1 ? 'entry' : 'entries'} this month', style: const TextStyle(color: C.slate, fontSize: 12)),
    
        ],
      ),
      children: [
       
        if (rows.isEmpty) const Panel(child: EmptyNote('No transactions this month.')),
        for (final t in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ObjectKey(t),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(t),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              child: Panel(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: catColor(t.category).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(catIcon(t.category), color: catColor(t.category)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.category, style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
                      Text('${DateFormat('dd MMM').format(t.date)}${t.name.isEmpty ? '' : ' · ${t.name}'}', style: const TextStyle(fontSize: 12, color: C.slate)),
                    ]),
                  ),
                  Text(
                    '${isCashIn(t.category) ? '+' : '−'}${aed(t.amount)}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: isCashIn(t.category) ? C.green : C.red),
                  ),
                ]),
              ),
            ),
          ),
        if (rows.isNotEmpty) const Center(child: Text('Swipe left on an entry to delete it.', style: TextStyle(color: C.slate, fontSize: 12))),
      ],
    );
  }
}