import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:fyp/LocalDB.dart';
import 'HeightPage.dart';

class BirthdayPage extends StatefulWidget {
  const BirthdayPage({super.key});

  @override
  State<BirthdayPage> createState() => _CreativeBirthdayPageState();
}

class _CreativeBirthdayPageState extends State<BirthdayPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedYear;

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
      begin: Colors.purple[50],
      end: Colors.pink[50],
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _selectedMonth != null &&
      _selectedDay != null &&
      _selectedYear != null;

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
                    colors: [_bgColorAnimation.value!, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Emojis
              const Positioned(top: 100, left: 30, child: Text('🎂', style: TextStyle(fontSize: 40))),
              const Positioned(top: 80, right: 40, child: Text('🎉', style: TextStyle(fontSize: 50))),
              const Positioned(bottom: 200, left: 50, child: Text('🎈', style: TextStyle(fontSize: 45))),
              const Positioned(bottom: 180, right: 60, child: Text('🧁', style: TextStyle(fontSize: 48))),
              
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        'When is your birthday?',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedOpacity(
                      opacity: _opacityAnimation.value,
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        'Let us know when we can celebrate your special day and personalize your plan.',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildDropdown(
                      hint: 'Select Month',
                      items: [
                        'January', 'February', 'March', 'April', 'May', 'June',
                        'July', 'August', 'September', 'October', 'November', 'December'
                      ],
                      value: _selectedMonth,
                      onChanged: (val) => setState(() => _selectedMonth = val),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            hint: 'Day',
                            items: List.generate(31, (i) => '${i + 1}'),
                            value: _selectedDay,
                            onChanged: (val) => setState(() => _selectedDay = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            hint: 'Year',
                            items: List.generate(50, (i) => '${1980 + i}'),
                            value: _selectedYear,
                            onChanged: (val) => setState(() => _selectedYear = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Material(
                        borderRadius: BorderRadius.circular(30),
                        elevation: 5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _isComplete
                              ? () async{
                            await LocalDB.setSelectedMonth(_selectedMonth!);
                            await LocalDB.setSelectedDay(_selectedDay!);
                            await LocalDB.setSelectedYear(_selectedYear!);
                               Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HeightPage()),
                                  );
                                  }
                              : null,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: _isComplete
                                  ? LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: textTheme.titleLarge?.copyWith(
                                  color: _isComplete ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required List<String> items,
    String? value,
    required void Function(String?) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(
          hint,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
        underline: const SizedBox(),
        items: items.map((val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(
              val,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
