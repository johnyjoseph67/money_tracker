import 'dart:math';

import 'models.dart';

int cashChange(Txn t) => isCashIn(t.category) ? t.amount : -t.amount;

class CashSummary {
  final int opening, salary, expenses, received, paid;
  final List<Txn> selected;
  CashSummary(this.opening, this.salary, this.expenses, this.received, this.paid, this.selected);
  int get closing => opening + salary + received - expenses - paid;
  int byCategory(String c) => selected.where((t) => t.category == c).fold<int>(0, (a, t) => a + t.amount);
}

CashSummary cashSummary(List<Txn> h, Map<String, int> salaries, String month, int initial) {
  var opening = initial;
  salaries.forEach((m, v) {
    if (m.compareTo(month) < 0) opening += v;
  });
  for (final t in h) {
    if (t.month.compareTo(month) < 0) opening += cashChange(t);
  }
  final sel = h.where((t) => t.month == month).toList();
  int sum(bool Function(Txn) f) => sel.where(f).fold<int>(0, (a, t) => a + t.amount);
  return CashSummary(
    opening,
    salaries[month] ?? 0,
    sum((t) => pairFor(t.category) == null),
    sum((t) => isCashIn(t.category) && pairFor(t.category) != null),
    sum((t) => t.category == 'Lend' || t.category == 'Settlement'),
    sel,
  );
}

class DebtRow {
  final String name, key;
  int opening = 0, added = 0, paid = 0;
  DebtRow(this.name, this.key);
  int get closing => opening + added - paid;
}

List<DebtRow> debtSummary(List<Txn> h, String month, Pair p) {
  final people = <String, DebtRow>{};
  for (final t in h) {
    if (t.month.compareTo(month) > 0 || (t.category != p.add && t.category != p.subtract)) continue;
    final key = t.key.isEmpty ? '__missing__' : t.key;
    final r = people.putIfAbsent(key, () => DebtRow(t.name.isEmpty ? 'NAME MISSING — correct the sheet' : t.name, key));
    if (t.month.compareTo(month) < 0) {
      r.opening += t.category == p.add ? t.amount : -t.amount;
    } else if (t.category == p.add) {
      r.added += t.amount;
    } else {
      r.paid += t.amount;
    }
  }
  return people.values.where((r) => r.opening != 0 || r.added != 0 || r.paid != 0).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

/// Every borrow/lend and settlement/repayment entry of one person, oldest first, up to the end of [month].
List<Txn> debtEntries(List<Txn> h, String month, Pair p, String key) {
  return h
      .where((t) =>
          (t.category == p.add || t.category == p.subtract) &&
          t.month.compareTo(month) <= 0 &&
          (t.key.isEmpty ? '__missing__' : t.key) == key)
      .toList()
    ..sort((a, b) {
      final c = a.day.compareTo(b.day);
      return c != 0 ? c : (a.category == p.add ? 0 : 1) - (b.category == p.add ? 0 : 1);
    });
}

class Pending {
  final String name;
  final int amount;
  Pending(this.name, this.amount);
}

List<Pending> pendingFrom(List<Txn> h, String day, String category) {
  final p = pairFor(category);
  if (p == null) return [];
  final people = <String, Pending>{};
  final totals = <String, int>{};
  for (final t in h) {
    if (t.key.isEmpty || t.day.compareTo(day) > 0 || (t.category != p.add && t.category != p.subtract)) continue;
    totals[t.key] = (totals[t.key] ?? 0) + (t.category == p.add ? t.amount : -t.amount);
    people.putIfAbsent(t.key, () => Pending(t.name, 0));
  }
  return [
    for (final e in totals.entries)
      if (e.value > 0) Pending(people[e.key]!.name, e.value)
  ]..sort((a, b) => a.name.compareTo(b.name));
}

bool _timelineOk(List<Txn> all, Pair pair, String key) {
  final tl = all.where((t) => t.key == key && (t.category == pair.add || t.category == pair.subtract)).toList()
    ..sort((a, b) {
      final c = a.day.compareTo(b.day);
      return c != 0 ? c : (a.category == pair.add ? 0 : 1) - (b.category == pair.add ? 0 : 1);
    });
  var bal = 0;
  for (final t in tl) {
    bal += t.category == pair.add ? t.amount : -t.amount;
    if (bal < 0) return false;
  }
  return true;
}

/// Same rules as the sheet: names required, repayment <= pending, no negative balance on any date.
String validateDebt(List<Txn> h, String category, String day, String name, int amount) {
  final pair = pairFor(category);
  if (pair == null) return cleanName(name);
  final key = nameKey(name);
  if (key.isEmpty) throw const FormatException('Enter or select the person’s name.');
  final original = h.where((t) => t.key == key && pairFor(t.category) != null).firstOrNull;
  final fixed = original?.name ?? cleanName(name);
  if (isRepayment(category)) {
    var pending = 0;
    for (final t in h) {
      if (t.key != key || t.day.compareTo(day) > 0) continue;
      if (t.category == pair.add) pending += t.amount;
      if (t.category == pair.subtract) pending -= t.amount;
    }
    if (amount > pending) {
      throw FormatException('Amount exceeds pending balance of AED ${aed(max(0, pending))} for this date.');
    }
    final probe = Txn(date: DateTime.parse(day), category: category, amount: amount, savedAt: DateTime.now(), name: fixed);
    if (!_timelineOk([...h, probe], pair, key)) {
      throw const FormatException('This entry conflicts with another repayment. Check dates and amounts.');
    }
  }
  return fixed;
}

/// Returns a message if removing entries would leave a negative pending balance.
String? deleteProblem(List<Txn> remaining) {
  for (final pair in [payablePair, receivablePair]) {
    final keys = remaining.where((t) => pairFor(t.category) == pair && t.key.isNotEmpty).map((t) => t.key).toSet();
    for (final k in keys) {
      if (!_timelineOk(remaining, pair, k)) {
        return 'Cannot delete: a later repayment would exceed the pending balance. Delete the repayment first.';
      }
    }
  }
  return null;
}