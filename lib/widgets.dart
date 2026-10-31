import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.color = Colors.white, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: child,
      );
}

class ScreenList extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? pinned; // stays fixed under the title (e.g. the month bar)
  final List<Widget> children; // only this part scrolls
  const ScreenList({super.key, required this.title, this.trailing, this.pinned, required this.children});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.navy))),
                  if (trailing != null) trailing!,
                ]),
                if (pinned != null) ...[const SizedBox(height: 12), pinned!],
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: children,
              ),
            ),
          ],
        ),
      );
}

class MonthBar extends StatelessWidget {
  final String month;
  final ValueChanged<String> onChanged;
  const MonthBar({super.key, required this.month, required this.onChanged});

  void _shift(int k) {
    final n = shiftMonth(month, k);
    if (n.compareTo('2020-01') >= 0 && n.compareTo('2040-12') <= 0) onChanged(n);
  }

  Future<void> _pick(BuildContext context) async {
    final months = allMonths();
    final idx = months.indexOf(month);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SizedBox(
        height: 420,
        child: ListView.builder(
          controller: ScrollController(initialScrollOffset: max(0, (idx - 3) * 56.0)),
          itemExtent: 56,
          itemCount: months.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(monthLabel(months[i])),
            selected: months[i] == month,
            selectedColor: C.teal,
            trailing: months[i] == month ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.pop(ctx, months[i]),
          ),
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
        child: Row(children: [
          IconButton.filledTonal(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous month'),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _pick(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(monthLabel(month), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.navy)),
              ),
            ),
          ),
          IconButton.filledTonal(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next month'),
        ]),
      );
}

class StatTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const StatTile({super.key, required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: C.slate))),
          ]),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color))),
        ]),
      );
}

class EmptyNote extends StatelessWidget {
  final String text;
  const EmptyNote(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: C.slate))));
}

InputDecoration deco(String label, {String? prefix}) => InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );

void toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? C.red : C.teal,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<void> showSalaryDialog(BuildContext context, String month) async {
  final app = context.read<AppState>();
  final ctrl = TextEditingController(text: (app.salaries[month] ?? 0) == 0 ? '' : ((app.salaries[month]!) / 100).toStringAsFixed(2));
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Salary — ${monthLabel(month)}'),
      content: TextField(controller: ctrl, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco('Monthly salary (AED)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final v = double.tryParse(ctrl.text.replaceAll(',', ''));
  if (v == null) {
    toast(context, 'Enter salary as zero or a positive amount.', error: true);
    return;
  }
  try {
    await app.setSalary(month, v);
  } catch (e) {
    if (context.mounted) toast(context, errText(e), error: true);
  }
}