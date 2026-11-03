import 'package:flutter/foundation.dart';

import 'logic.dart';
import 'models.dart';
import 'session_store.dart';
import 'sheets_api.dart';

String errText(Object e) => e is FormatException ? e.message : e.toString();

class AppState extends ChangeNotifier {
  final _api = SheetsApi();
  final _store = SessionStore();

  // session
  bool ready = false; // saved session has been read
  UserInfo? user;
  Account? account; // saved Web app URL + token
  Credentials? savedCredentials; // set when 'Remember password' was ticked
  bool get signedIn => user != null;

  // data
  List<Txn> history = [];
  Map<String, int> salaries = {};
  int initial = 0;
  bool loading = false;
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

  /// App start: read the saved session; if signed in, load the data.
  Future<void> init() async {
    account = await _store.loadAccount();
    user = await _store.loadUser();
    savedCredentials = await _store.loadCredentials();
    if (account != null && user != null) {
      _api.configure(account!.url, account!.token);
      loading = true;
    } else {
      user = null;
    }
    ready = true;
    notifyListeners();
    if (loading) await load();
  }

  // ---------- registration / login ----------
  Future<void> testConnection(String url, String token) => _run(() => _api.post(url, token, 'ping'));

  Future<void> register({required String name, required String username, required String password, required String url, required String token}) async {
    final data = await _run(() => _api.post(url, token, 'register', {'name': name, 'username': username, 'password': password}));
    await _signedIn(Account(url.trim(), token.trim()), data['user'] as Map<String, dynamic>);
  }

  /// Uses the saved connection unless a URL and token are given (first sign-in on a new device).
  Future<void> login({required String username, required String password, bool remember = false, String? url, String? token}) async {
    final typed = (url ?? '').trim().isNotEmpty && (token ?? '').trim().isNotEmpty;
    final acc = typed ? Account(url!.trim(), token!.trim()) : account;
    if (acc == null) throw const FormatException('Enter the Web app URL and API token.');
    final data = await _run(() => _api.post(acc.url, acc.token, 'login', {'username': username, 'password': password}));
    if (remember) {
      await _store.saveCredentials(username, password);
      savedCredentials = Credentials(username, password);
    } else {
      await _store.clearCredentials();
      savedCredentials = null;
    }
    await _signedIn(acc, data['user'] as Map<String, dynamic>);
  }

  Future<void> _signedIn(Account acc, Map<String, dynamic> u) async {
    account = acc;
    user = UserInfo(u['username'] as String, u['name'] as String);
    await _store.saveAccount(acc);
    await _store.saveUser(user!);
    _api.configure(acc.url, acc.token);
    loading = true;
    error = null;
    notifyListeners();
    await load();
  }

  Future<void> logout() async {
    user = null;
    history = [];
    salaries = {};
    initial = 0;
    error = null;
    loading = false;
    await _store.clearUser();
    notifyListeners();
  }

  // ---------- data ----------
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