import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:fyp/LocalDB.dart';
import 'package:fyp/main_navigation.dart';
import 'package:fyp/models/user_details.dart';
import 'package:fyp/services/config_service.dart';

class FoodieAnalysisPage extends StatefulWidget {
  const FoodieAnalysisPage({super.key});

  @override
  State<FoodieAnalysisPage> createState() => _FoodieAnalysisPageState();
}

class _FoodieAnalysisPageState extends State<FoodieAnalysisPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  bool _isComplete = false;
  int _currentStep = 0;
  Timer? _stepTimer;

  final List<String> _processingSteps = [
    "Gathering fresh ingredients...",
    "Analyzing your preferences...",
    "Blending the perfect flavors...",
    "Adding a dash of science...",
    "Plating your masterpiece...",
  ];
  
  final profile = UserDetails(
    user: LocalDB.getUser(),
    authToken: LocalDB.getAuthToken(),
    userName: LocalDB.getUserName(),
    selectedMonth: LocalDB.getSelectedMonth(),
    selectedDay: LocalDB.getSelectedDay(),
    selectedYear: LocalDB.getSelectedYear(),
    height: LocalDB.getHeight(),
    currentWeight: LocalDB.getCurrentWeight(),
    targetWeight: LocalDB.getTargetWeight(),
    selectedSubGoals: LocalDB.getSelectedSubGoals(),
    selectedHabits: LocalDB.getSelectedHabits(),
    activityLevels: LocalDB.getActivityLevels(),
    scheduleIcons: LocalDB.getScheduleIcons(),
    healthConcerns: LocalDB.getHealthConcerns(),
    levels: LocalDB.getLevels(),
    options: LocalDB.getOptions(),
    mealOptions: LocalDB.getMealOptions(),
    waterOptions: LocalDB.getWaterOptions(),
    restrictions: LocalDB.getRestrictions(),
    eatingStyles: LocalDB.getEatingStyles(),
    startTimes: LocalDB.getStartTimes(),
    endTimes: LocalDB.getEndTimes(),
    waterGoal: '5 L'
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _progressAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!_isComplete && mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _processingSteps.length;
        });
      }
    });

    _controller.forward();
    _callAPIs().then((_) {
      _controller.forward().whenComplete(() {
        if (mounted) {
          setState(() {
            _isComplete = true;
            _currentStep = 0;
          });
        }
      });
    });
  }

  Map<String, dynamic> profileToJson(UserDetails profile) {
    return {
      // ✅ CHANGE: Added userName to the JSON payload
      'userName': profile.userName, 
      'height': profile.height,
      'currentWeight': profile.currentWeight,
      'targetWeight': profile.targetWeight,
      'activityLevels': profile.activityLevels,
      'healthConcerns': profile.healthConcerns ?? {},
      'restrictions': profile.restrictions ?? {},
      'eatingStyles': profile.eatingStyles ?? {},
      'selectedSubGoals': profile.selectedSubGoals?.toList() ?? [],
      'selectedHabits': profile.selectedHabits?.toList() ?? [],
      'waterGoal' : '5 L'
    };
  }

  Future<void> _callAPIs() async {
    try {
      final authToken = await LocalDB.getAuthToken();
      if (authToken == null) return;
      final url = Uri.parse('$baseURL/api/user-details/my-profile');
      final headers = {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': 'Bearer $authToken'};
      final body = jsonEncode(profileToJson(profile));
      await http.post(url, headers: headers, body: body);
    } catch (e) {
      debugPrint("Error in _callAPIs(): $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isComplete ? Colors.teal.shade50 : colorScheme.primaryContainer,
                  _isComplete ? Colors.green.shade100 : colorScheme.secondaryContainer,
                ],
              ),
            ),
          ),

          // New static background stickers widget
          const _BackgroundStickers(),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: 200,
                  height: 250,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => CustomPaint(
                      painter: _BlenderPainter(
                        progress: _progressAnim.value,
                        isComplete: _isComplete,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _isComplete ? 'Your Plan is Ready!' : 'Cooking Up Your Plan...',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: Text(
                    _isComplete ? 'Enjoy your personalized journey to health.' : _processingSteps[_currentStep],
                    key: ValueKey<String>(_isComplete.toString() + _processingSteps[_currentStep]),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                AnimatedOpacity(
                  opacity: _isComplete ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: _isComplete ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavigationWrapper()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu_rounded, color: Colors.white),
                      label: Text(
                        "View My Plan!",
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                        shadowColor: Colors.green.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A widget to manage the continuous animation of the background stickers.
class _BackgroundStickers extends StatefulWidget {
  const _BackgroundStickers();

  @override
  State<_BackgroundStickers> createState() => _BackgroundStickersState();
}

class _BackgroundStickersState extends State<_BackgroundStickers>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // A list to hold the generated data for each sticker.
  final List<Map<String, dynamic>> _stickerData = [];
  
  // --- You can easily change this number to add more or fewer stickers! ---
  final int stickerCount = 25;
  
  final List<String> _icons = ['🍓', '🥦', '🏋️‍♀️', '💧', '🥗', '🧘‍♀️', '🥕', '🥑', '💪', '🍎'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Procedurally generate the sticker data once.
    for (int i = 0; i < stickerCount; i++) {
      _stickerData.add({
        'icon': _icons[i % _icons.length],
        'size': 30.0 + math.Random().nextDouble() * 25.0,
        // Positions are generated as percentages (0.0 to 1.0) of screen size.
        'top': math.Random().nextDouble(),
        'left': math.Random().nextDouble(),
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _stickerData.map((data) {
            // This logic ensures stickers are pushed away from the center.
            double top = data['top'] * constraints.maxHeight;
            double left = data['left'] * constraints.maxWidth;
            
            // If the sticker is in the middle horizontal third...
            if (left > constraints.maxWidth * 0.3 && left < constraints.maxWidth * 0.7) {
              // ...push it to the left or right edge.
              left = left < constraints.maxWidth / 2 ? 0.1 * constraints.maxWidth : 0.9 * constraints.maxWidth;
            }

            // If the sticker is in the middle vertical third...
            if (top > constraints.maxHeight * 0.3 && top < constraints.maxHeight * 0.7) {
                // ...push it to the top or bottom edge.
              top = top < constraints.maxHeight / 2 ? 0.1 * constraints.maxHeight : 0.9 * constraints.maxHeight;
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = math.sin(_controller.value * 2 * math.pi + (data['top'] * data['left'] * 10)) * 10;
                return Positioned(
                  top: top + offset,
                  left: left,
                  child: Text(
                    data['icon'],
                    style: TextStyle(fontSize: data['size'], color: Colors.black.withOpacity(0.07)),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _BlenderPainter extends CustomPainter {
  final double progress;
  final bool isComplete;
  final Color color;

  _BlenderPainter({required this.progress, required this.isComplete, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.1), color.withOpacity(0.4)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    final basePaint = Paint()..color = color.withOpacity(0.15);
    final liquidPaint = Paint()..color = isComplete ? Colors.green.shade300 : color.withOpacity(0.6);
    final bladePaint = Paint()..color = Colors.grey.shade400..strokeWidth = 3..strokeCap = StrokeCap.round;

    final jarPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.1)
      ..lineTo(size.width * 0.85, size.height * 0.1)
      ..lineTo(size.width * 0.75, size.height * 0.8)
      ..lineTo(size.width * 0.25, size.height * 0.8)
      ..close();
      
    final basePath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(size.width * 0.2, size.height * 0.8, size.width * 0.8, size.height * 0.95),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ));
      
    final lidPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(size.width * 0.1, 0, size.width * 0.9, size.height * 0.1),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ));

    canvas.drawPath(basePath, basePaint);
    canvas.drawPath(lidPath, basePaint..color = color.withOpacity(0.3));
    
    canvas.save();
    canvas.clipPath(jarPath);

    if (progress > 0) {
      final liquidLevel = size.height * 0.8 * (1 - progress * 0.8);
      final wavePath = Path()..moveTo(0, liquidLevel);
      for (double x = 0; x <= size.width; x++) {
        final y = liquidLevel + math.sin((x * 0.1) + (progress * math.pi * 4)) * 3;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(size.width, size.height);
      wavePath.lineTo(0, size.height);
      wavePath.close();
      canvas.drawPath(wavePath, liquidPaint);

      final bubblePaint = Paint()..color = Colors.white.withOpacity(0.5);
      for (int i = 0; i < 10; i++) {
        final bubbleProgress = (progress * 2 + i * 0.1) % 1.0;
        final bubbleX = size.width * 0.25 + (i / 10) * (size.width * 0.5);
        final bubbleY = size.height * 0.8 - (size.height * 0.7 * bubbleProgress);
        final bubbleRadius = (1 - bubbleProgress) * 3 + 1;
        if (bubbleY > liquidLevel) {
          canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius, bubblePaint);
        }
      }
    }
    
    if (isComplete) {
      final checkPaint = Paint()..color = Colors.white..strokeWidth = 8..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
      final checkPath = Path()
        ..moveTo(size.width * 0.35, size.height * 0.45)
        ..lineTo(size.width * 0.48, size.height * 0.58)
        ..lineTo(size.width * 0.65, size.height * 0.4);
      canvas.drawPath(checkPath, checkPaint);
    }
    canvas.restore();
    
    canvas.drawPath(jarPath, glassPaint);
    
    final bladeRotation = progress * math.pi * 12;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.75);
    canvas.rotate(bladeRotation);
    canvas.drawLine(const Offset(-15, 0), const Offset(15, 0), bladePaint);
    canvas.drawLine(const Offset(0, -15), const Offset(0, 15), bladePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlenderPainter oldDelegate) {
    return progress != oldDelegate.progress || isComplete != oldDelegate.isComplete;
  }
}