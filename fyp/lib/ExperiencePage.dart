import 'package:flutter/material.dart';
import 'MessagePage1.dart';

class WeightLossFamiliarityPage extends StatefulWidget {
  const WeightLossFamiliarityPage({super.key});

  @override
  State<WeightLossFamiliarityPage> createState() =>
      _WeightLossFamiliarityPageState();
}

class _WeightLossFamiliarityPageState extends State<WeightLossFamiliarityPage> {
  int? selectedLevel;
  final PageController _pageController = PageController(viewportFraction: 0.75);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> levels = [
      {
        'title': 'BEGINNER',
        'description': 'I\'m new to weight loss and need to learn a lot',
        'icon': Icons.eco,
        'color': colorScheme.primary,
        'subtitle': 'Just starting my journey',
      },
      {
        'title': 'INTERMEDIATE',
        'description': 'I have some experience but still need guidance',
        'icon': Icons.directions_run,
        'color': colorScheme.secondary,
        'subtitle': 'Building my knowledge',
      },
      {
        'title': 'MASTER',
        'description': 'I have rich experience',
        'icon': Icons.workspace_premium,
        'color': colorScheme.tertiary ?? colorScheme.secondaryContainer,
        'subtitle': 'Sharing my wisdom',
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  selectedLevel != null
                      ? levels[selectedLevel!]['color'].withOpacity(0.2)
                      : colorScheme.surfaceVariant.withOpacity(0.2),
                  colorScheme.surface,
                ],
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      'HOW FAMILIAR ARE YOU WITH',
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'WEIGHT LOSS?',
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: selectedLevel != null ? 120 : 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selectedLevel != null
                            ? levels[selectedLevel!]['color']
                            : colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 4,
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(levels.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: selectedLevel == index ? 24 : 16,
                                height: selectedLevel == index ? 24 : 16,
                                decoration: BoxDecoration(
                                  color: selectedLevel == index
                                      ? levels[index]['color']
                                      : colorScheme.onSurface.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedLevel == index
                                        ? colorScheme.surface
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                levels[index]['title'],
                                style: TextStyle(
                                  color: selectedLevel == index
                                      ? colorScheme.onBackground
                                      : colorScheme.onBackground
                                          .withOpacity(0.6),
                                  fontWeight: selectedLevel == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
Expanded(
  child: PageView.builder(
    controller: _pageController,
    itemCount: levels.length,
    onPageChanged: (index) =>
        setState(() => selectedLevel = index),
    itemBuilder: (context, index) {
      final level = levels[index];
      final isSelected = selectedLevel == index;

      return AnimatedScale(
        scale: isSelected ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: colorScheme.surfaceVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    level['icon'],
                    size: 80,
                    color: level['color'],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    level['subtitle'],
                    style: TextStyle(
                      color: level['color'],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level['title'],
                    style: TextStyle(
                      color: level['color'],
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      level['description'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ),
),

              Padding(
                padding: const EdgeInsets.all(32),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selectedLevel != null
                        ? levels[selectedLevel!]['color']
                        : colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: selectedLevel != null
                            ? levels[selectedLevel!]['color'].withOpacity(0.5)
                            : Colors.transparent,
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: 
                          () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AITrackerPage()),
                              );
                            },
                      child: Center(
                        child: Text(
                          'CONTINUE JOURNEY',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
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
