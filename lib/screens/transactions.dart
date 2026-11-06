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
  String? filter; // null = all categories

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

  Widget _chip(String label, {required bool selected, required Color color, IconData? icon, required VoidCallback onTap}) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          showCheckmark: false,
          avatar: icon == null ? null : Icon(icon, size: 18, color: selected ? Colors.white : color),
          label: Text(label),
          selected: selected,
          selectedColor: color,
          backgroundColor: Colors.white,
          side: BorderSide.none,
          labelStyle: TextStyle(color: selected ? Colors.white : C.navy, fontWeight: FontWeight.w600),
          onSelected: (_) => onTap(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.history.where((t) => t.month == month).toList()
      ..sort((a, b) {
        final c = b.day.compareTo(a.day);
        return c != 0 ? c : b.savedAt.compareTo(a.savedAt);
      });
    final rows = filter == null ? all : all.where((t) => t.category == filter).toList();

    // only offer categories that exist this month (plus the one currently selected)
    final present = categories.where((c) => all.any((t) => t.category == c)).toList();
    if (filter != null && !present.contains(filter)) present.add(filter!);
    final total = rows.fold<int>(0, (a, t) => a + t.amount);

    return ScreenList(
      title: 'Transactions',
      pinned: Column(children: [
        MonthBar(month: month, onChanged: (m) => setState(() => month = m)),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip('All', selected: filter == null, color: C.teal, icon: Icons.apps_rounded, onTap: () => setState(() => filter = null)),
            for (final c in present) _chip(c, selected: filter == c, color: catColor(c), icon: catIcon(c), onTap: () => setState(() => filter = c)),
          ]),
        ),
      ]),
      children: [
        Row(children: [
          Expanded(
            child: Text(
              filter == null ? '${all.length} ${all.length == 1 ? 'entry' : 'entries'} this month' : '${rows.length} of ${all.length} entries · $filter',
              style: const TextStyle(color: C.slate, fontSize: 12),
            ),
          ),
          if (filter != null && rows.isNotEmpty) Text('Total AED ${aed(total)}', style: TextStyle(color: catColor(filter!), fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Panel(
            child: Column(children: [
              EmptyNote(filter == null ? 'No transactions this month.' : 'No $filter transactions this month.'),
              if (filter != null) TextButton(onPressed: () => setState(() => filter = null), child: const Text('Clear filter')),
            ]),
          ),
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