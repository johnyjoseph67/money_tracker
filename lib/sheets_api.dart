import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class Snapshot {
  final List<Txn> txns;
  final Map<String, int> salaries;
  final int initial;
  Snapshot(this.txns, this.salaries, this.initial);
}

/// Talks to the Apps Script web app. URL and token come from registration / login (not from source code).
class SheetsApi {
  String? url, token;

  void configure(String u, String t) {
    url = u.trim();
    token = t.trim();
  }

  /// Data calls: every call returns the full, fresh snapshot.
  Future<Snapshot> call(String action, [Map<String, dynamic> extra = const {}]) async {
    final u = url, t = token;
    if (u == null || t == null) throw const FormatException('Not connected. Please sign in again.');
    return _parse(await post(u, t, action, extra));
  }

  /// Low-level call with an explicit URL and token (register, login, test connection).
  Future<Map<String, dynamic>> post(String u, String t, String action, [Map<String, dynamic> extra = const {}]) async {
    if (!u.trim().startsWith('https://')) throw const FormatException('Enter the full Web app URL, starting with https://');
    if (t.trim().isEmpty) throw const FormatException('Enter the API token.');
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(u.trim()))
        ..followRedirects = false // Apps Script answers POST with a redirect; we follow it with GET
        ..headers['Content-Type'] = 'text/plain;charset=utf-8'
        ..body = jsonEncode({'token': t.trim(), 'action': action, ...extra});
      var res = await http.Response.fromStream(await client.send(req)).timeout(const Duration(seconds: 90));
      if (res.statusCode >= 300 && res.statusCode < 400) {
        final loc = res.headers['location'];
        if (loc == null) throw const FormatException('Unexpected reply from Google.');
        res = await client.get(Uri.parse(loc)).timeout(const Duration(seconds: 90));
      }
      Map<String, dynamic> map;
      try {
        map = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        throw const FormatException('Unexpected reply. In the deployment, set Execute as: Me and Who has access: Anyone, then deploy a new version.');
      }
      if (map['ok'] != true) throw FormatException(map['error']?.toString() ?? 'Request failed.');
      return (map['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Network problem. Check your internet connection and the URL, then try again.');
    } finally {
      client.close();
    }
  }

  Snapshot _parse(Map<String, dynamic> d) {
    final txns = [for (final t in (d['transactions'] as List)) _txn(t as Map<String, dynamic>)];
    final sal = <String, int>{
      for (final e in (d['salaries'] as Map<String, dynamic>).entries) e.key: (e.value as num).round(),
    };
    return Snapshot(txns, sal, (d['initial'] as num).round());
  }

  Txn _txn(Map<String, dynamic> m) {
    final date = DateTime.parse(m['date'] as String);
    return Txn(
      date: DateTime(date.year, date.month, date.day),
      category: m['category'] as String,
      amount: (m['amount'] as num).round(),
      savedAt: DateTime.tryParse((m['savedAt'] ?? '') as String)?.toLocal() ?? date,
      name: (m['name'] ?? '') as String,
      row: (m['row'] as num).toInt(),
    );
  }
}