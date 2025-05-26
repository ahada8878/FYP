import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterIntakeChart extends StatefulWidget {
  final bool showWeekly;
  final Function(bool) onToggle;

  const WaterIntakeChart({
    super.key,
    required this.showWeekly,
    required this.onToggle,
  });

  @override
  State<WaterIntakeChart> createState() => _WaterIntakeChartState();
}

class _WaterIntakeChartState extends State<WaterIntakeChart> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Water Intake',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  child: BarChart(_chartData()),
                ),
              ],
            ),
          ),
        ),
        _buildToggle(),
      ],
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Week'),
          Switch(
            value: widget.showWeekly,
            onChanged: widget.onToggle,
            activeColor: const Color.fromRGBO(106, 79, 153, 1),
          ),
          const Text('Month'),
        ],
      ),
    );
  }

  BarChartData _chartData() {
    final weeklyData = [2.5, 3.0, 2.0, 2.8, 3.5, 2.2, 3.0];
    final monthlyData = List.generate(30, (i) => 2.0 + (i % 5 * 0.5));

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              widget.showWeekly 
                  ? ['S', 'M', 'T', 'W', 'T', 'F', 'S'][value.toInt()]
                  : '${value.toInt() + 1}'),
            reservedSize: 32,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}L'),
            reservedSize: 40,
          ),
        ),
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
      ),
      borderData: FlBorderData(show: false),
      barGroups: (widget.showWeekly ? weeklyData : monthlyData)
          .asMap()
          .entries
          .map((e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: const Color.fromRGBO(106, 79, 153, 0.6),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              ))
          .toList(),
    );
  }
}