import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'logic.dart';
import 'models.dart';
import 'theme.dart';

const _palette = [C.teal, C.mint, C.blue, C.orange, Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFCA8A04), Color(0xFF64748B)];

class SpendDonut extends StatelessWidget {
  final CashSummary cash;
  const SpendDonut(this.cash, {super.key});
  @override
  Widget build(BuildContext context) {
    final items = [
      for (final c in spendCategories) MapEntry<String, int>(c, cash.byCategory(c)),
    ].where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (items.isEmpty) return const SizedBox(height: 90, child: Center(child: Text('No spending this month', style: TextStyle(color: C.slate))));
    final total = items.fold<int>(0, (a, e) => a + e.value);
    return Row(children: [
      SizedBox(
        width: 140,
        height: 140,
        child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 38, sections: [
          for (var i = 0; i < items.length; i++)
            PieChartSectionData(value: items[i].value / 100, color: _palette[i % _palette.length], radius: 26, showTitle: false),
        ])),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(children: [
          for (var i = 0; i < items.length && i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(items[i].key, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                Text('${(items[i].value * 100 / total).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

const _hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

class MiniBars extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  const MiniBars({super.key, required this.labels, required this.values, required this.colors});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 170,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: _hidden,
            rightTitles: _hidden,
            topTitles: _hidden,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[v.toInt()], style: const TextStyle(fontSize: 11, color: C.slate)),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [BarChartRodData(toY: values[i], color: colors[i], width: 24, borderRadius: BorderRadius.circular(8))]),
          ],
        )),
      );
}

class TrendLines extends StatelessWidget {
  final List<Txn> history;
  final Map<String, int> salaries;
  final int initial;
  final String month;
  const TrendLines({super.key, required this.history, required this.salaries, required this.initial, required this.month});

  LineChartBarData _line(List<double> ys, Color c) => LineChartBarData(
        spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
        isCurved: true,
        color: c,
        barWidth: 3,
        dotData: const FlDotData(show: false),
      );

  @override
  Widget build(BuildContext context) {
    final months = [for (var i = -11; i <= 0; i++) shiftMonth(month, i)];
    final sums = months.map((m) => cashSummary(history, salaries, m, initial)).toList();
    return Column(children: [
      SizedBox(
        height: 190,
        child: LineChart(LineChartData(
          minX: 0,
          maxX: 11,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: _hidden,
            rightTitles: _hidden,
            topTitles: _hidden,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (v, meta) => v.toInt() % 2 != 0
                    ? const SizedBox.shrink()
                    : Padding(padding: const EdgeInsets.only(top: 8), child: Text(shortMonth(months[v.toInt()]), style: const TextStyle(fontSize: 11, color: C.slate))),
              ),
            ),
          ),
          lineBarsData: [
            _line(sums.map((s) => s.salary / 100).toList(), C.teal),
            _line(sums.map((s) => s.expenses / 100).toList(), C.red),
            _line(sums.map((s) => s.closing / 100).toList(), C.blue),
          ],
        )),
      ),
      const SizedBox(height: 8),
      const Wrap(spacing: 16, children: [
        _Key('Salary', C.teal),
        _Key('Expenses / Savings', C.red),
        _Key('Closing cash', C.blue),
      ]),
    ]);
  }
}

class _Key extends StatelessWidget {
  final String text;
  final Color color;
  const _Key(this.text, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: C.slate)),
      ]);
}
