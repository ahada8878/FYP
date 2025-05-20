import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;

class FoodieAnalysisPage extends StatefulWidget {
  const FoodieAnalysisPage({super.key});

  @override
  State<FoodieAnalysisPage> createState() => _FoodieAnalysisPageState();
}

class _FoodieAnalysisPageState extends State<FoodieAnalysisPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<double> _bounceAnim;
  late Animation<Color?> _colorAnim;
  
  bool _isComplete = false;
  final List<String> _foodEmojis = ['🍎', '🥑', '🍗', '🥦', '🍓', '🥚', '🍕', '🍣'];
  final List<Offset> _emojiPositions = [];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _progressAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _bounceAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _colorAnim = ColorTween(
      begin: Colors.orange[200],
      end: Colors.purple[200],
    ).animate(_controller);

    // Initialize random emoji positions
    for (int i = 0; i < _foodEmojis.length; i++) {
      _emojiPositions.add(Offset(
        math.Random().nextDouble() * 300,
        math.Random().nextDouble() * 300,
      ));
    }

    _controller.forward().then((_) => setState(() => _isComplete = true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // **Animated Gradient Kitchen Background**
          AnimatedBuilder(
            animation: _colorAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _colorAnim.value!.withOpacity(0.2),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // **Floating Food Emojis**
          for (int i = 0; i < _foodEmojis.length; i++)
            Positioned(
              left: _emojiPositions[i].dx,
              top: _emojiPositions[i].dy,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -20 * math.sin(_progressAnim.value * 2 * math.pi + i)),
                  child: Text(
                    _foodEmojis[i],
                    style: TextStyle(
                      fontSize: 30 + 10 * math.sin(_progressAnim.value * 2 * math.pi),
                    ),
                  ),
                ),
              ),
            ),

          // **Main Content**
          Column(
            children: [
              // **Animated Chef Hat Header**
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -20 * (1 - _bounceAnim.value)),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('👨‍🍳', style: const TextStyle(fontSize: 80)),
                        Positioned(
                          top: -40,
                          child: Transform.scale(
                            scale: 1 + 0.2 * math.sin(_progressAnim.value * 2 * math.pi),
                            child: const Text('🎩', style: TextStyle(fontSize: 40)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // **Progress Title**
              Text(
                'Cooking Up Your Perfect Plan!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _colorAnim.value,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // **Food Processor Animation**
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => CustomPaint(
                        painter: _FoodProcessorPainter(_progressAnim.value),
                      ),
                    ),
                  ),
                  Text(
                    '${(_progressAnim.value * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _colorAnim.value,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // **Recipe Card Steps**
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final steps = [
                      "Slicing your nutrition data...",
                      "Mixing diet preferences...",
                      "Seasoning with your goals...",
                      "Garnishing with recommendations..."
                    ];
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => Transform.scale(
                        scale: 0.9 + 0.1 * math.sin(_progressAnim.value * 2 * math.pi + index),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              steps[index],
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Spacer(),

              // **Complete Button**
              if (_isComplete)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Transform.scale(
                    scale: 1 + 0.1 * math.sin(_progressAnim.value * 4 * math.pi),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorAnim.value,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Serve My Plan! ",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text('🍽️', style: TextStyle(fontSize: 24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodProcessorPainter extends CustomPainter {
  final double progress;

  _FoodProcessorPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    // Draw processor blades
    for (int i = 0; i < 3; i++) {
      final angle = 2 * math.pi * i / 3 + progress * 2 * math.pi;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * 0.7 * math.cos(angle),
          center.dy + radius * 0.7 * math.sin(angle),
        ),
        paint,
      );
    }

    // Draw food pieces
    for (int i = 0; i < 8; i++) {
      final angle = 2 * math.pi * i / 8;
      final dist = radius * 0.3 + radius * 0.4 * progress;
      canvas.drawCircle(
        Offset(
          center.dx + dist * math.cos(angle),
          center.dy + dist * math.sin(angle),
        ),
        5 + 10 * progress,
        Paint()..color = Colors.primaries[i % Colors.primaries.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}