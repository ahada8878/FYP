import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WeeklyReportSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final ScrollController scrollController;

  const WeeklyReportSheet({
    super.key,
    required this.data,
    required this.scrollController,
  });

  @override
  State<WeeklyReportSheet> createState() => _WeeklyReportSheetState();
}

class _WeeklyReportSheetState extends State<WeeklyReportSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Helper to remove emojis/special chars that crash the default PDF font
  String _cleanText(String text) {
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  Future<void> _generatePdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating PDF..."), duration: Duration(seconds: 1)),
    );

    try {
      final pdf = pw.Document();
      
      final summary = _cleanText(widget.data['summary'] ?? "Weekly summary.");
      final tips = List<String>.from(widget.data['tips'] ?? []).map((t) => _cleanText(t)).toList();
      final macros = widget.data['macros_percentage'] ?? {'protein': 33, 'carbs': 33, 'fat': 33};
      final dailyChart = List<Map<String, dynamic>>.from(widget.data['daily_chart'] ?? []);
      final micronutrients = List<Map<String, dynamic>>.from(widget.data['micronutrients'] ?? []);
      final analysis = widget.data['analysis'] ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text("Weekly Health Analysis", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              pw.Text("Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Paragraph(text: summary),
              pw.SizedBox(height: 20),
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
                    return [_cleanText(e['day'].toString()), cal.toString(), goal.toString(), status];
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              if (micronutrients.isNotEmpty) ...[
                pw.Text("Micronutrients", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...micronutrients.map((m) => pw.Bullet(text: "${_cleanText(m['name'])}: ${_cleanText(m['status'])} - ${_cleanText(m['insight'])}")),
                pw.SizedBox(height: 20),
              ],
              if (analysis['strengths'] != null) ...[
                pw.Text("Strengths", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...(analysis['strengths'] as List).map((s) => pw.Bullet(text: _cleanText(s.toString()))),
                pw.SizedBox(height: 10),
              ],
              if (analysis['improvements'] != null) ...[
                pw.Text("Areas to Improve", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ...(analysis['improvements'] as List).map((s) => pw.Bullet(text: _cleanText(s.toString()))),
                pw.SizedBox(height: 20),
              ],
              pw.Text("Actionable Tips", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ...tips.map((t) => pw.Bullet(text: t)),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'My_Weekly_Health_Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final summary = widget.data['summary'] ?? "Your weekly health summary.";
    final tips = List<String>.from(widget.data['tips'] ?? []);
    final macros = widget.data['macros_percentage'] ?? {'protein': 33, 'carbs': 33, 'fat': 33};
    final dailyChart = List<Map<String, dynamic>>.from(widget.data['daily_chart'] ?? []);
    final micronutrients = List<Map<String, dynamic>>.from(widget.data['micronutrients'] ?? []);
    final analysis = widget.data['analysis'] ?? {};

    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA), // Light, clean background
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // Extra bottom padding for button
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.auto_awesome, color: Colors.orange.shade700, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("WEEKLY RECAP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[600])),
                          Text("Health Analysis", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 1. Summary Card (Hero)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.white, Colors.orange.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                      border: Border.all(color: Colors.orange.shade100.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(Icons.summarize_rounded, color: Colors.orange.shade800, size: 22), const SizedBox(width: 8), Text("Executive Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade900))]),
                        const SizedBox(height: 12),
                        Text(summary, style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Macro Split
                  Text("Macronutrient Balance", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CustomPaint(
                              painter: _DonutChartPainter(
                                protein: (macros['protein'] ?? 0).toDouble(),
                                carbs: (macros['carbs'] ?? 0).toDouble(),
                                fat: (macros['fat'] ?? 0).toDouble(),
                              ),
                              child: Center(child: Text("Macros", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[400], fontSize: 12))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem("Protein", const Color(0xFF42A5F5), macros['protein']),
                              const SizedBox(height: 12),
                              _buildLegendItem("Carbs", const Color(0xFF66BB6A), macros['carbs']),
                              const SizedBox(height: 12),
                              _buildLegendItem("Fats", const Color(0xFFFFA726), macros['fat']),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. Daily Calories Chart
                  Text("Calories vs Goal", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
                    child: SizedBox(height: 180, child: _AnimatedBarChart(data: dailyChart)),
                  ),
                  const SizedBox(height: 32),

                  // 4. Micronutrients
                  if (micronutrients.isNotEmpty) ...[
                    Text("Micronutrients", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: micronutrients.map((m) => _buildMicroCard(m)).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // 5. Strengths & Weaknesses
                  if (analysis['strengths'] != null && (analysis['strengths'] as List).isNotEmpty)
                    _buildBoxedListSection("💪 Strengths", analysis['strengths'], Colors.green.shade50, Colors.green.shade700),

                  const SizedBox(height: 16),

                  if (analysis['improvements'] != null && (analysis['improvements'] as List).isNotEmpty)
                    _buildBoxedListSection("📉 Areas to Improve", analysis['improvements'], Colors.red.shade50, Colors.red.shade700),

                  const SizedBox(height: 32),

                  // 6. Actionable Tips
                  Text("Actionable Tips", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle), child: Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(tip, style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[800]))),
                        ],
                      ),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),

          // Floating Download Button
          Positioned(
            left: 24, right: 24, bottom: 24,
            child: SlideTransition(
              position: _slideAnimation,
              child: ElevatedButton.icon(
                onPressed: () => _generatePdf(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 8,
                  shadowColor: primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text("Download PDF Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, dynamic value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[700])),
        const Spacer(),
        Text("$value%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _buildMicroCard(Map<String, dynamic> m) {
    bool isGood = m['status'] == 'Good';
    Color bg = isGood ? Colors.green.shade50 : Colors.red.shade50;
    Color text = isGood ? Colors.green.shade800 : Colors.red.shade800;
    
    return Container(
      width: (MediaQuery.of(context).size.width - 60) / 2, // 2 columns
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: text, fontSize: 15)),
          const SizedBox(height: 6),
          Text(m['insight'] ?? '', style: TextStyle(fontSize: 12, color: text.withOpacity(0.8), height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBoxedListSection(String title, List<dynamic> items, Color bgColor, Color titleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: BoxDecoration(color: titleColor, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(item.toString(), style: TextStyle(height: 1.4, fontSize: 14, color: Colors.grey[800]))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

// --- CREATIVE PAINTERS & WIDGETS ---

class _DonutChartPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  _DonutChartPainter({required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = protein + carbs + fat;
    
    // Draw background track
    final bgPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..color = Colors.grey.shade100;
    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    final pP = (protein / total) * 2 * math.pi;
    final pC = (carbs / total) * 2 * math.pi;
    final pF = (fat / total) * 2 * math.pi;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round;

    // Draw segments with spacing
    double startAngle = -math.pi / 2;
    
    paint.color = const Color(0xFF66BB6A); // Green Carbs
    canvas.drawArc(rect, startAngle, pC - 0.1, false, paint);
    startAngle += pC;

    paint.color = const Color(0xFF42A5F5); // Blue Protein
    canvas.drawArc(rect, startAngle, pP - 0.1, false, paint);
    startAngle += pP;

    paint.color = const Color(0xFFFFA726); // Orange Fat
    canvas.drawArc(rect, startAngle, pF - 0.1, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _AnimatedBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text("No daily data available"));

    double maxVal = 2200; 
    for (var d in data) {
      double cal = (d['calories'] as num).toDouble();
      if (cal > maxVal) maxVal = cal;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((day) {
        final cal = (day['calories'] as num).toDouble();
        final goal = (day['goal'] as num).toDouble();
        final pct = (cal / maxVal).clamp(0.0, 1.0);

        Color barColor = const Color(0xFFFFA726);
        if (cal > goal * 1.15) barColor = const Color(0xFFEF5350);
        else if (cal >= goal * 0.85) barColor = const Color(0xFF66BB6A);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(cal.toStringAsFixed(0), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 6),
            // 🔥 Live Growth Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Container(
                width: 14,
                height: 120 * value,
                decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(height: 8),
            Text(day['day'].toString().substring(0, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        );
      }).toList(),
    );
  }
}