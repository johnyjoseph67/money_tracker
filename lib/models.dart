import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

const categories = <String>[
  'Food & Groceries', 'Transport', 'Rent', 'Utilities', 'Shopping', 'Health', 'Entertainment',
  'Education', 'Travel', 'Other', 'India', 'Savings', 'Outside Food', 'Borrow', 'Settlement',
  'Lend', 'Received Repayment',
];

class Pair {
  final String add, subtract;
  const Pair(this.add, this.subtract);
}

const payablePair = Pair('Borrow', 'Settlement');
const receivablePair = Pair('Lend', 'Received Repayment');

Pair? pairFor(String c) {
  if (c == payablePair.add || c == payablePair.subtract) return payablePair;
  if (c == receivablePair.add || c == receivablePair.subtract) return receivablePair;
  return null;
}

bool isRepayment(String c) => c == 'Settlement' || c == 'Received Repayment';
bool isCashIn(String c) => c == 'Borrow' || c == 'Received Repayment';
bool isNamed(String c) => c == 'Borrow' || c == 'Lend';
final spendCategories = categories.where((c) => pairFor(c) == null).toList();

String cleanName(String v) => v.trim().replaceAll(RegExp(r'\s+'), ' ');
String nameKey(String v) => cleanName(v).toLowerCase();
int toCents(num v) => (v * 100).round();
String aed(int cents) => NumberFormat('#,##0.00').format(cents / 100);
String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
bool validMonth(String m) => RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(m);
String currentMonth() => DateFormat('yyyy-MM').format(DateTime.now());
DateTime _firstOf(String m) => DateTime(int.parse(m.substring(0, 4)), int.parse(m.substring(5, 7)), 1);
String shiftMonth(String m, int k) {
  final d = _firstOf(m);
  return DateFormat('yyyy-MM').format(DateTime(d.year, d.month + k, 1));
}

String monthLabel(String m) => DateFormat('MMMM yyyy').format(_firstOf(m));
String shortMonth(String m) => DateFormat('MMM').format(_firstOf(m));
List<String> allMonths() => [for (var y = 2020; y <= 2040; y++) for (var m = 1; m <= 12; m++) '$y-${m.toString().padLeft(2, '0')}'];

class Txn {
  final DateTime date;
  final String category, name, day, month, key;
  final int amount; // cents
  final int row; // row number in the Google Sheet (0 = unknown)
  final DateTime savedAt;
  Txn({required this.date, required this.category, required this.amount, required this.savedAt, required String name, this.row = 0})
      : name = cleanName(name),
        key = nameKey(name),
        day = dayKey(date),
        month = dayKey(date).substring(0, 7);
}

IconData catIcon(String c) {
  switch (c) {
    case 'Food & Groceries': return Icons.shopping_basket_rounded;
    case 'Transport': return Icons.directions_bus_rounded;
    case 'Rent': return Icons.home_rounded;
    case 'Utilities': return Icons.bolt_rounded;
    case 'Shopping': return Icons.shopping_bag_rounded;
    case 'Health': return Icons.favorite_rounded;
    case 'Entertainment': return Icons.movie_rounded;
    case 'Education': return Icons.school_rounded;
    case 'Travel': return Icons.flight_rounded;
    case 'India': return Icons.public_rounded;
    case 'Savings': return Icons.savings_rounded;
    case 'Outside Food': return Icons.restaurant_rounded;
    case 'Borrow': case 'Received Repayment': return Icons.south_west_rounded;
    case 'Lend': case 'Settlement': return Icons.north_east_rounded;
    default: return Icons.category_rounded;
  }
}

Color catColor(String c) {
  final p = pairFor(c);
  if (p == payablePair) return C.orange;
  if (p == receivablePair) return C.blue;
  return C.teal;
}
