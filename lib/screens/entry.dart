import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../logic.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final amountCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  String? category;
  String? pendingName;
  DateTime date = DateTime.now();
  bool saving = false;

  @override
  void dispose() {
    amountCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2040, 12, 31));
    if (d != null) setState(() {
      date = d;
      pendingName = null;
    });
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', ''));
    if (amount == null) return toast(context, 'Enter an amount of at least AED 0.01.', error: true);
    final c = category;
    if (c == null) return toast(context, 'Select a valid category.', error: true);
    final name = isRepayment(c) ? (pendingName ?? '') : (isNamed(c) ? nameCtrl.text : '');
    setState(() => saving = true);
    try {
      await app.addTransaction(amount: amount, category: c, date: date, name: name);
      amountCtrl.clear();
      nameCtrl.clear();
      pendingName = null;
      if (mounted) toast(context, 'Saved successfully');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = category;
    final pending = c != null && isRepayment(c) ? pendingFrom(app.history, dayKey(date), c) : <Pending>[];
    return ScreenList(
      title: 'New entry',
      children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Amount (AED)', style: TextStyle(color: C.slate, fontSize: 12)),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: C.navy),
              decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Category', style: TextStyle(color: C.slate, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final cat in categories)
            ChoiceChip(
              showCheckmark: false,
              avatar: Icon(catIcon(cat), size: 18, color: cat == c ? Colors.white : catColor(cat)),
              label: Text(cat),
              selected: cat == c,
              selectedColor: catColor(cat),
              backgroundColor: Colors.white,
              side: BorderSide.none,
              labelStyle: TextStyle(color: cat == c ? Colors.white : C.navy, fontWeight: FontWeight.w600),
              onSelected: (_) => setState(() {
                category = cat;
                pendingName = null;
                nameCtrl.clear();
              }),
            ),
        ]),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date', style: TextStyle(fontSize: 12, color: C.slate)),
            subtitle: Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.navy)),
            trailing: const Icon(Icons.calendar_month_rounded, color: C.teal),
            onTap: _pickDate,
          ),
        ),
        if (c != null && isNamed(c)) ...[
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words, decoration: deco(c == 'Borrow' ? 'Borrowed from — name' : 'Lent to — name')),
        ],
        if (c != null && isRepayment(c)) ...[
          const SizedBox(height: 16),
          Text(c == 'Settlement' ? 'Pay back (pending names)' : 'Received from (pending names)', style: const TextStyle(color: C.slate, fontSize: 12)),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Text('No pending names for this category and date.', style: TextStyle(color: C.slate))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in pending)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text('${p.name} · AED ${aed(p.amount)}'),
                  selected: pendingName == p.name,
                  selectedColor: C.chip,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => pendingName = p.name),
                ),
            ]),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : const Text('Save entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        const Center(child: Text('Saved to your Excel workbook on this device.', style: TextStyle(color: C.slate, fontSize: 12))),
      ],
    );
  }
}
