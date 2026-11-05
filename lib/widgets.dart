import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Page body: an optional fixed header (e.g. the month bar) and a scrolling list.
/// The title/trailing parameters are kept so existing screens compile; the shell's app bar shows the title.
class ScreenList extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? pinned; // stays fixed under the app bar
  final List<Widget> children; // only this part scrolls
  const ScreenList({super.key, required this.title, this.trailing, this.pinned, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (pinned != null) Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: pinned!),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, pinned == null ? 16 : 4, 20, 24),
              children: children,
            ),
          ),
        ],
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

/// Salary "top-up" dialog for the selected month.
Future<void> showSalaryDialog(BuildContext context, String month) async {
  final app = context.read<AppState>();
  final value = await showDialog<double>(
    context: context,
    builder: (_) => _SalaryDialog(month: month, current: app.salaries[month] ?? 0),
  );
  if (value == null || !context.mounted) return;
  try {
    await app.setSalary(month, value);
  } catch (e) {
    if (context.mounted) toast(context, errText(e), error: true);
  }
}

class _SalaryDialog extends StatefulWidget {
  final String month;
  final int current; // cents
  const _SalaryDialog({required this.month, required this.current});
  @override
  State<_SalaryDialog> createState() => _SalaryDialogState();
}

class _SalaryDialogState extends State<_SalaryDialog> {
  late final TextEditingController ctrl;
  String? error;

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.current == 0 ? '' : (widget.current / 100).toStringAsFixed(2));
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(ctrl.text.replaceAll(',', '')) ?? 0;

  void _add(int amount) {
    final text = (_value + amount).toStringAsFixed(2);
    setState(() {
      error = null;
      ctrl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    });
  }

  void _save() {
    final v = double.tryParse(ctrl.text.replaceAll(',', ''));
    if (v == null || v < 0) {
      setState(() => error = 'Enter salary as zero or a positive amount.');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: C.chip, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: C.teal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Set salary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.navy)),
                  const SizedBox(height: 2),
                  Text(monthLabel(widget.month), style: const TextStyle(fontSize: 13, color: C.slate)),
                ]),
              ),
              IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: C.slate)),
            ]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Monthly salary', style: TextStyle(fontSize: 12, color: C.slate)),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  onChanged: (_) => setState(() => error = null),
                  onSubmitted: (_) => _save(),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: C.navy),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    prefixText: 'AED ',
                    prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.teal),
                    errorText: error,
                  ),
                ),
              ]),
            ),
            if (widget.current > 0) ...[
              const SizedBox(height: 10),
              Text('Current salary: AED ${aed(widget.current)}', style: const TextStyle(fontSize: 12, color: C.slate)),
            ],
            const SizedBox(height: 14),
            const Text('Quick add', style: TextStyle(fontSize: 12, color: C.slate)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final q in const [500, 1000, 5000])
                ActionChip(
                  label: Text('+${q >= 1000 ? '${q ~/ 1000},000' : q}'),
                  labelStyle: const TextStyle(color: C.teal, fontWeight: FontWeight.w700),
                  backgroundColor: C.chip,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _add(q),
                ),
              ActionChip(
                label: const Text('Clear'),
                labelStyle: const TextStyle(color: C.slate, fontWeight: FontWeight.w600),
                backgroundColor: C.paper,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => setState(() {
                  error = null;
                  ctrl.clear();
                }),
              ),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.slate,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: C.teal,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save salary', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      );
}