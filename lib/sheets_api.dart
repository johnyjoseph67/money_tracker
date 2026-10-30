import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class Snapshot {
  final List<Txn> txns;
  final Map<String, int> salaries;
  final int initial;
  Snapshot(this.txns, this.salaries, this.initial);
}

/// Talks to the Apps Script web app. Every call returns the full, fresh snapshot.
class SheetsApi {
  Future<Snapshot> call(String action, [Map<String, dynamic> extra = const {}]) async {
    if (sheetsUrl.contains('XXXX') || sheetsToken.startsWith('PUT-A-LONG')) {
      throw const FormatException('Set sheetsUrl and sheetsToken in lib/config.dart.');
    }
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(sheetsUrl))
        ..followRedirects = false // Apps Script answers POST with a redirect; we follow it with GET
        ..headers['Content-Type'] = 'text/plain;charset=utf-8'
        ..body = jsonEncode({'token': sheetsToken, 'action': action, ...extra});
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
      return _parse(map['data'] as Map<String, dynamic>);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Network problem. Check your internet connection and try again.');
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
