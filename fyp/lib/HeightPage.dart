import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'WeightPage.dart';

class HeightPage extends StatefulWidget {
  const HeightPage({super.key});

  @override
  State<HeightPage> createState() => _CreativeHeightPageState();
}

class _CreativeHeightPageState extends State<HeightPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  int selectedFeet = 5;
  int selectedInches = 11;
  int selectedCentimeters = 170;
  bool isMetric = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _bgColorAnimation = ColorTween(
      begin: Colors.blue[50],
      end: Colors.purple[50],
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
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Animated background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _bgColorAnimation.value!,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Floating emojis
              const Positioned(top: 90, left: 30, child: Text('🧍‍♂️', style: TextStyle(fontSize: 40))),
              const Positioned(top: 120, right: 40, child: Text('📏', style: TextStyle(fontSize: 42))),
              const Positioned(bottom: 180, left: 40, child: Text('🧬', style: TextStyle(fontSize: 45))),
              const Positioned(bottom: 160, right: 60, child: Text('📐', style: TextStyle(fontSize: 42))),

              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: IconButton(
                            icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            'Your Height',
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        FadeTransition(
                          opacity: _opacityAnimation,
                          child: Text(
                            'Let us know your height to personalize your experience.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onBackground.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Toggle buttons
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMeasurementButton('cm', isMetric, colorScheme),
                              _buildMeasurementButton('in', !isMetric, colorScheme),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Picker
                        isMetric ? _buildCentimeterPicker(colorScheme) : _buildFeetInchPicker(colorScheme),

                        const SizedBox(height: 32),

                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Material(
                            borderRadius: BorderRadius.circular(30),
                            elevation: 5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const WeightPage()),
                                );
                              },
                              child: Container(
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: LinearGradient(
                                    colors: [colorScheme.primary, colorScheme.secondary],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'CONTINUE',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMeasurementButton(String text, bool isActive, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(() => isMetric = text == 'cm'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFeetInchPicker(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPickerColumn('ft', 4, 7, selectedFeet, (v) => selectedFeet = v, colorScheme),
        const SizedBox(width: 24),
        _buildPickerColumn('in', 0, 11, selectedInches, (v) => selectedInches = v, colorScheme),
      ],
    );
  }

  Widget _buildCentimeterPicker(ColorScheme colorScheme) {
    return SizedBox(
      height: 200,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50,
        perspective: 0.01,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => setState(() => selectedCentimeters = 100 + index),
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final cm = 100 + index;
            return Center(
              child: Text(
                '$cm cm',
                style: TextStyle(
                  fontSize: 32,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
          childCount: 100,
        ),
      ),
    );
  }

  Widget _buildPickerColumn(String label, int start, int end, int selectedValue, Function(int) onChanged, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          width: 80,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.01,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => setState(() => onChanged(start + index)),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = start + index;
                return Center(
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 32,
                      color: value == selectedValue
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              childCount: end - start + 1,
            ),
          ),
        ),
      ],
    );
  }
}
