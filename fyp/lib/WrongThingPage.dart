import 'package:fyp/LocalDB.dart';

import 'package:flutter/material.dart';
import 'MessagePage2.dart';

class PostMealRegretPage extends StatefulWidget {
  const PostMealRegretPage({super.key});

  @override
  State<PostMealRegretPage> createState() => _PostMealRegretPageState();
}

class _PostMealRegretPageState extends State<PostMealRegretPage>
    with SingleTickerProviderStateMixin {
  int? selectedOption;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  final List<Map<String, dynamic>> options = [
    {
      'text': 'I always regret',
      'emoji': '😫',
      'color': Colors.red,
      'subtext': 'Every meal feels like a mistake'
    },
    {
      'text': 'Sometimes',
      'emoji': '😕',
      'color': Colors.orange,
      'subtext': 'Certain foods trigger regret'
    },
    {
      'text': 'Rarely',
      'emoji': '🙂',
      'color': Colors.green,
      'subtext': 'I usually make good choices'
    },
    {
      'text': 'Never',
      'emoji': '😊',
      'color': Colors.blue,
      'subtext': 'I enjoy my meals guilt-free'
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey[200],
      end: Colors.purple[100],
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selectedOption != null
                      ? options[selectedOption!]['color'].withOpacity(0.1)
                      : colorScheme.surfaceContainerHighest,
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Floating food items with opacity animation
          Positioned(
            top: 100,
            left: 30,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: selectedOption == 0 ? 1.0 : 0.3,
              child: const Text('🍔', style: TextStyle(fontSize: 40)),
            ),
          ),
          Positioned(
            top: 80,
            right: 40,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: selectedOption == 1 ? 1.0 : 0.3,
              child: const Text('🍕', style: TextStyle(fontSize: 50)),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 50,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: selectedOption == 2 ? 1.0 : 0.3,
              child: const Text('🥗', style: TextStyle(fontSize: 45)),
            ),
          ),
          Positioned(
            bottom: 180,
            right: 60,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: selectedOption == 3 ? 1.0 : 0.3,
              child: const Text('🍎', style: TextStyle(fontSize: 48)),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated title
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'After eating...',
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: colorScheme.primary.withOpacity(0.2),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _opacityAnimation.value,
                        child: Text(
                          'Do you suffer for having eaten the wrong thing?',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Option cards
                      ...List.generate(options.length, (index) {
                        final option = options[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedOption = index;
                            });
                            _animationController.reset();
                            _animationController.forward();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: selectedOption == index
                                  ? option['color'].withOpacity(0.2)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedOption == index
                                    ? option['color']
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: selectedOption == index
                                      ? option['color'].withOpacity(0.2)
                                      : Colors.transparent,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selectedOption == index
                                        ? option['color']
                                        : colorScheme.onSurface
                                            .withOpacity(0.1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      option['emoji'],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['text'],
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option['subtext'],
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: selectedOption == index ? 1.0 : 0.0,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: option['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 40),

                      // Continue button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: selectedOption != null ? 1.0 : 0.6,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: selectedOption != null
                                ? LinearGradient(
                                    colors: [
                                      options[selectedOption!]['color'],
                                      options[selectedOption!]['color']
                                          .withOpacity(0.7),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      colorScheme.onSurface.withOpacity(0.3),
                                      colorScheme.onSurface.withOpacity(0.1),
                                    ],
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedOption != null
                                    ? options[selectedOption!]['color']
                                        .withOpacity(0.4)
                                    : Colors.transparent,
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: selectedOption != null
                                  ? () async{
                            await LocalDB.setOptions(options[selectedOption!]['text']);
                                   
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const AITrackerPage2()),
                                      );
                                    }
                                  : null,
                              child: Center(
                                child: Text(
                                  'CONTINUE',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: selectedOption != null
                                        ? Colors.white
                                        : colorScheme.onSurface
                                            .withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
