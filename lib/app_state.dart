import 'package:flutter/foundation.dart';

import 'logic.dart';
import 'models.dart';
import 'sheets_api.dart';

String errText(Object e) => e is FormatException ? e.message : e.toString();

class AppState extends ChangeNotifier {
  final _api = SheetsApi();
  List<Txn> history = [];
  Map<String, int> salaries = {};
  int initial = 0;
  bool loading = true;
  String? error;
  DateTime? lastSync;

  int _busyCount = 0;

  /// True while any API call is running (drives the centre loading indicator).
  bool get busy => _busyCount > 0;

  Future<T> _run<T>(Future<T> Function() job) async {
    _busyCount++;
    notifyListeners();
    try {
      return await job();
    } finally {
      _busyCount--;
      notifyListeners();
    }
  }

  void _apply(Snapshot s) {
    history = s.txns;
    salaries = s.salaries;
    initial = s.initial;
    lastSync = DateTime.now();
    notifyListeners();
  }

  /// First load (shows the overlay, then the error page if it fails).
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _run(() async => _apply(await _api.call('load')));
    } catch (e) {
      error = errText(e);
    }
    loading = false;
    notifyListeners();
  }

  /// Re-sync; errors go to the caller.
  Future<void> refresh() => _run(() async => _apply(await _api.call('load')));

  Future<void> addTransaction({required double amount, required String category, required DateTime date, String name = ''}) async {
    final value = toCents(amount);
    if (value <= 0) throw const FormatException('Enter an amount of at least AED 0.01.');
    if (!categories.contains(category)) throw const FormatException('Select a valid category.');
    final fixed = validateDebt(history, category, dayKey(date), name, value); // same rules as the sheet
    await _run(() async => _apply(await _api.call('add', {'amount': value / 100, 'category': category, 'date': dayKey(date), 'name': fixed})));
  }

  Future<void> deleteTransaction(Txn t) async {
    final next = history.where((x) => !identical(x, t)).toList();
    final problem = deleteProblem(next);
    if (problem != null) throw FormatException(problem);
    await _run(() async => _apply(await _api.call('delete', {'row': t.row, 'date': t.day, 'category': t.category, 'amountCents': t.amount})));
  }

  Future<void> setSalary(String month, double v) async {
    if (!validMonth(month)) throw const FormatException('Select a valid salary month.');
    if (v < 0) throw const FormatException('Enter salary as zero or a positive amount.');
    await _run(() async => _apply(await _api.call('salary', {'month': month, 'value': v})));
  }

  Future<void> setInitial(double v) => _run(() async => _apply(await _api.call('initial', {'value': v})));
}