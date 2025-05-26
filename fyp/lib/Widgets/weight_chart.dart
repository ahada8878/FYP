import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightChart extends StatefulWidget {
  final double currentWeight;

  const WeightChart({super.key, required this.currentWeight});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  late List<FlSpot> _weightSpots;

  @override
  void initState() {
    super.initState();
    _generateWeightSpots();
  }

  @override
  void didUpdateWidget(WeightChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWeight != widget.currentWeight) {
      _generateWeightSpots();
    }
  }

  void _generateWeightSpots() {
    final baseWeight = widget.currentWeight;
    _weightSpots = [
      FlSpot(0, baseWeight + 0.2),
      FlSpot(1, baseWeight + 0.5),
      FlSpot(2, baseWeight + 0.1),
      FlSpot(3, baseWeight - 0.1),
      FlSpot(4, baseWeight - 0.2),
      FlSpot(5, baseWeight - 0.0),
      FlSpot(6, baseWeight - 0.3),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final minY = _weightSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = _weightSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 0.5;

    return Card(
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
              'Weight Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()]),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => 
                          Text('${value.toStringAsFixed(1)}kg'),
                        reservedSize: 50,
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _weightSpots,
                      isCurved: true,
                      color: const Color.fromRGBO(106, 79, 153, 1),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: minY,
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}