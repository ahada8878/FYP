import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WeeklyReportSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScrollController scrollController;

  const WeeklyReportSheet({
    super.key,
    required this.data,
    required this.scrollController,
  });

  /// Helper to remove emojis/special chars that crash the default PDF font
  String _cleanText(String text) {
    // This regex replaces non-ASCII characters (like emojis) with an empty string
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  Future<void> _generatePdf(BuildContext context) async {
    // 1. Feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating PDF..."), duration: Duration(seconds: 1)),
    );

    try {
      final pdf = pw.Document();
      
      // Prepare Data (Cleaned of emojis)
      final summary = _cleanText(data['summary'] ?? "Weekly summary.");
      final tips = List<String>.from(data['tips'] ?? []).map((t) => _cleanText(t)).toList();
      final macros = data['macros_percentage'] ?? {'protein': 33, 'carbs': 33, 'fat': 33};
      final dailyChart = List<Map<String, dynamic>>.from(data['daily_chart'] ?? []);
      final micronutrients = List<Map<String, dynamic>>.from(data['micronutrients'] ?? []);
      final analysis = data['analysis'] ?? {};

      // 2. Build PDF Page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text("Weekly Health Analysis", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              
              pw.Text("Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Paragraph(text: summary),
              pw.SizedBox(height: 20),
              
              // Macros Table
              pw.Text("Macronutrient Split", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Protein: ${macros['protein']}%", style: const pw.TextStyle(color: PdfColors.blue)),
                  pw.Text("Carbs: ${macros['carbs']}%", style: const pw.TextStyle(color: PdfColors.green)),
                  pw.Text("Fats: ${macros['fat']}%", style: const pw.TextStyle(color: PdfColors.orange)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Daily Calories Table (Replaces Chart for PDF stability)
              pw.Text("Daily Intake vs Goal", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.center,
                data: <List<String>>[
                  <String>['Day', 'Calories', 'Goal', 'Status'],
                  ...dailyChart.map((e) {
                    final cal = e['calories'] ?? 0;
                    final goal = e['goal'] ?? 2000;
                    final status = cal > goal * 1.1 ? "Over" : (cal < goal * 0.9 ? "Under" : "Good");
                    return [
                      _cleanText(e['day'].toString()), 
                      cal.toString(), 
                      goal.toString(),
                      status
                    ];
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              // Micronutrients
              if (micronutrients.isNotEmpty) ...[
                pw.Text("Micronutrients", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...micronutrients.map((m) => pw.Bullet(
                  text: "${_cleanText(m['name'])}: ${_cleanText(m['status'])} - ${_cleanText(m['insight'])}"
                )),
                pw.SizedBox(height: 20),
              ],

              // Strengths
              if (analysis['strengths'] != null) ...[
                pw.Text("Strengths", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...(analysis['strengths'] as List).map((s) => pw.Bullet(text: _cleanText(s.toString()))),
                pw.SizedBox(height: 10),
              ],
              
              // Improvements
              if (analysis['improvements'] != null) ...[
                pw.Text("Areas to Improve", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...(analysis['improvements'] as List).map((s) => pw.Bullet(text: _cleanText(s.toString()))),
                pw.SizedBox(height: 20),
              ],

              // Tips
              pw.Text("Actionable Tips", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ...tips.map((t) => pw.Bullet(text: t)),
            ];
          },
        ),
      );

      // 3. Open Native Print Preview (Best way to Save as PDF)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'My_Weekly_Health_Report',
      );

    } catch (e) {
      // 4. Error Feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely access data with defaults
    final summary = data['summary'] ?? "Your weekly health summary.";
    final tips = List<String>.from(data['tips'] ?? []);
    final macros = data['macros_percentage'] ?? {'protein': 33, 'carbs': 33, 'fat': 33};
    final dailyChart = List<Map<String, dynamic>>.from(data['daily_chart'] ?? []);
    final micronutrients = List<Map<String, dynamic>>.from(data['micronutrients'] ?? []);
    final analysis = data['analysis'] ?? {};

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Drag Handle
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                "Weekly Health Analysis",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 1. Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Text(
            summary,
            style: TextStyle(fontSize: 15, color: Colors.orange.shade900, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),

        // 2. Macro Pie Chart Section
        Text("Macronutrient Split", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 4,
                child: CustomPaint(
                  size: const Size(150, 150),
                  painter: _MacroPiePainter(
                    protein: (macros['protein'] ?? 0).toDouble(),
                    carbs: (macros['carbs'] ?? 0).toDouble(),
                    fat: (macros['fat'] ?? 0).toDouble(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem("Protein", Colors.blue, macros['protein']),
                    _buildLegendItem("Carbs", Colors.green, macros['carbs']),
                    _buildLegendItem("Fats", Colors.orange, macros['fat']),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 3. Daily Calorie Chart
        Text("Calories vs Goal", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: _ReportBarChart(data: dailyChart),
        ),
        const SizedBox(height: 32),

        // 4. Micronutrients Grid
        if (micronutrients.isNotEmpty) ...[
          Text("Micronutrients", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: micronutrients.map((m) => _buildMicroCard(m)).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // 5. Analysis Sections
        if (analysis['strengths'] != null && (analysis['strengths'] as List).isNotEmpty)
          _buildBulletSection("💪 Strengths", analysis['strengths']),
        
        if (analysis['improvements'] != null && (analysis['improvements'] as List).isNotEmpty)
          _buildBulletSection("📉 Areas to Improve", analysis['improvements']),

        // 6. Actionable Tips
        const SizedBox(height: 8),
        Text("Actionable Tips", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 10,
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.4))),
                ],
              ),
            )).toList(),

        const SizedBox(height: 32), 

        // ✅ PDF DOWNLOAD BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _generatePdf(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: const Icon(Icons.download_rounded),
            label: const Text("Download PDF Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 40), // Bottom padding for scroll
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text("$label: $value%", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  Widget _buildMicroCard(Map<String, dynamic> m) {
    bool isGood = m['status'] == 'Good';
    Color bg = isGood ? Colors.green.shade50 : Colors.red.shade50;
    Color text = isGood ? Colors.green.shade800 : Colors.red.shade800;
    Color border = isGood ? Colors.green.shade100 : Colors.red.shade100;

    return Container(
      width: 160, // Fixed width for grid effect
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: text, fontSize: 14)),
          const SizedBox(height: 4),
          Text(m['insight'] ?? '', style: TextStyle(fontSize: 12, color: text.withOpacity(0.8), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildBulletSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item.toString(), style: const TextStyle(height: 1.4, fontSize: 14))),
                ],
              ),
            )).toList(),
        const SizedBox(height: 24),
      ],
    );
  }
}

// --- CUSTOM PAINTERS ---

class _MacroPiePainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  _MacroPiePainter({required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = protein + carbs + fat;
    if (total == 0) return;

    // Convert percentages to radians (2 * pi = 360 degrees)
    final pP = (protein / total) * 2 * math.pi;
    final pC = (carbs / total) * 2 * math.pi;
    final pF = (fat / total) * 2 * math.pi;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt; // Clean edges for pie segments

    // Draw Carbs (Green)
    paint.color = Colors.green;
    canvas.drawArc(rect, -math.pi / 2, pC, false, paint);

    // Draw Protein (Blue)
    paint.color = Colors.blue;
    canvas.drawArc(rect, -math.pi / 2 + pC, pP, false, paint);

    // Draw Fat (Orange)
    paint.color = Colors.orange;
    canvas.drawArc(rect, -math.pi / 2 + pC + pP, pF, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReportBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _ReportBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No daily data available"));

    // Find maximum value to scale the bars
    double maxVal = 2000; 
    for (var d in data) {
      double cal = (d['calories'] as num).toDouble();
      double goal = (d['goal'] as num).toDouble();
      if (cal > maxVal) maxVal = cal;
      if (goal > maxVal) maxVal = goal;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((day) {
        final cal = (day['calories'] as num).toDouble();
        final goal = (day['goal'] as num).toDouble();
        
        // Calculate height percentage relative to maxVal
        final pct = (cal / maxVal).clamp(0.0, 1.0);

        // Color logic
        Color barColor = Colors.blue;
        if (cal > goal * 1.15) {
          barColor = Colors.redAccent; // Way over goal
        } else if (cal >= goal * 0.85) {
          barColor = Colors.green; // Good range (+/- 15%)
        } else {
          barColor = Colors.orangeAccent; // Under goal
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(cal.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: 140 * pct, // 140 is max height in pixels
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day['day'].toString().substring(0, 3),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }).toList(),
    );
  }
}