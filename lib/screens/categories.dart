import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../logic.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String month = currentMonth();

  Widget _row(String c, CashSummary cash, {bool showShare = true}) {
    final v = cash.byCategory(c);
    final share = cash.expenses == 0 ? 0.0 : v / cash.expenses;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Row(children: [
          Icon(catIcon(c), size: 20, color: catColor(c)),
          const SizedBox(width: 10),
          Expanded(child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy))),
          Text(aed(v), style: const TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(width: 52, child: Text(showShare ? '${(share * 100).toStringAsFixed(1)}%' : '—', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: C.slate))),
        ]),
        if (showShare)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: share, minHeight: 6, color: catColor(c), backgroundColor: const Color(0xFFE2E8F0)),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cash = cashSummary(app.history, app.salaries, month, app.initial);
    return ScreenList(
      title: 'Categories',
      pinned: MonthBar(month: month, onChanged: (m) => setState(() => month = m)),
      children: [
        Panel(
          color: C.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total expenses / savings', style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 13)),
            Text('AED ${aed(cash.expenses)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 16),
        Panel(child: Column(children: [for (final c in spendCategories) _row(c, cash)])),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Debt movements', style: TextStyle(fontWeight: FontWeight.w700, color: C.navy))),
        Panel(child: Column(children: [for (final c in categories.where((c) => pairFor(c) != null)) _row(c, cash, showShare: false)])),
      ],
    );
  }
}