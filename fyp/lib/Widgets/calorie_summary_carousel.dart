// calorie_summary_carousel.dart
import 'package:flutter/material.dart';
import 'package:fyp/Widgets/activity_log_sheet.dart';
import 'package:fyp/calorie_tracker_controller.dart';
import 'package:fyp/models/activity_model.dart';
import 'package:provider/provider.dart';

class CalorieSummaryCarousel extends StatefulWidget {
  const CalorieSummaryCarousel({super.key});

  @override
  State<CalorieSummaryCarousel> createState() => _CalorieSummaryCarouselState();
}

class _CalorieSummaryCarouselState extends State<CalorieSummaryCarousel>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() => setState(() {}));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.grey[50], // Match your home page's background color
          child: SizedBox(
            height: 260,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => _currentPage.value = index,
              children: const [
                _CalorieIntakeCard(),
                _CalorieBurnCard(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PageIndicator(currentPage: _currentPage),
      ],
    );
  }
}

class _CalorieIntakeCard extends StatelessWidget {
  const _CalorieIntakeCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalorieTrackerController>(
        builder: (context, tracker, child) {
      final caloriesLeft = tracker.dailyGoal - tracker.totalCalories;
      final progress = tracker.totalCalories / tracker.dailyGoal;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              title: 'Calorie Intake',
              subtitle: 'Daily Goal',
              value: '${tracker.dailyGoal} cal',
              valueColor: Colors.red,
              onEdit: () => _showEditGoalDialog(context),
            ),
            const SizedBox(height: 12),
            Center(
              child: _CircularProgressRing(
                progress: progress,
                fillColor: const Color.fromRGBO(106, 79, 153, 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$caloriesLeft',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'calories left',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _ProLockSection(),
          ],
        ),
      );
    });
  }

  void _showEditGoalDialog(BuildContext context) {
    final tracker =
        Provider.of<CalorieTrackerController>(context, listen: false);
    TextEditingController textController =
        TextEditingController(text: tracker.dailyGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Daily Goal'),
        content: TextFormField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Calories'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGoal =
                  int.tryParse(textController.text) ?? tracker.dailyGoal;
              tracker.setDailyGoal(newGoal);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CalorieBurnCard extends StatelessWidget {
  const _CalorieBurnCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalorieTrackerController>(builder: (context, tracker, _) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSection(
                    title: 'Daily Calorie Burn',
                    value: '${tracker.totalBurnedCalories} cal',
                    valueColor: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: _CircularProgressRing(
                      progress: tracker.totalBurnedCalories / 400,
                      fillColor: const Color.fromRGBO(106, 79, 153, 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${tracker.totalBurnedCalories}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'calories burned',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 80,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final selectedActivity =
                              await showModalBottomSheet<Activity>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const ActivityLogSheet(),
                          );

                          if (selectedActivity != null) {
                            // Handle selected activity
                            print('Selected: ${selectedActivity.name} '
                                '(${selectedActivity.caloriesPerMin} cal/5min)');
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Log'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _SideWidgets(),
          ],
        ),
      );
    });
  }
}

class _HeaderSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final Color valueColor;
  final VoidCallback? onEdit;

  const _HeaderSection({
    required this.title,
    this.subtitle,
    required this.value,
    required this.valueColor,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
          ],
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircularProgressRing extends StatelessWidget {
  final double progress;
  final Color fillColor;
  final Widget child;

  const _CircularProgressRing({
    required this.progress,
    required this.fillColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100, // Smaller size
      height: 100,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress,
          fillColor: fillColor,
          backgroundColor: Colors.grey[200]!,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.fillColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Background
    paint.color = backgroundColor;
    canvas.drawCircle(center, radius, paint);

    // Progress
    paint.color = fillColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.1416,
      2 * 3.1416 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ProLockSection extends StatelessWidget {
  const _ProLockSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(106, 79, 153, 1),
            Color.fromRGBO(106, 79, 153, 0.5)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(106, 79, 153, 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Unlock PRO to see your macros',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideWidgets extends StatelessWidget {
  const _SideWidgets();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalorieTrackerController>(builder: (context, tracker, _) {
      return Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          const _InfoBox(
            icon: Icons.directions_walk,
            text: 'Sync with Health',
            buttonLabel: 'Connect →',
          ),
          const SizedBox(height: 12),
          tracker.latestActivity != null
              ? _LatestActivityBox(
                  activity: tracker.latestActivity!,
                  duration: tracker.latestDuration!,
                  calories: tracker.latestCalories!,
                )
              : const _InfoBox(
                  icon: Icons.sentiment_dissatisfied,
                  text: 'No logged activity',
                ),
        ],
      );
    });
  }
}

class _LatestActivityBox extends StatelessWidget {
  final String activity;
  final int duration;
  final int calories;

  const _LatestActivityBox({
    required this.activity,
    required this.duration,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Activity Name and Icon
          Row(
            children: [
              const Icon(Icons.fitness_center, 
                color: Color.fromRGBO(106, 79, 153, 1), 
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Duration and Calories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$duration',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(106, 79, 153, 1),
                    ),
                  ),
                  const Text(
                    'mins',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              Column(
                children: [
                  Text(
                    '$calories',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(106, 79, 153, 1),
                    ),
                  ),
                  const Text(
                    'cal',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? buttonLabel;

  const _InfoBox({
    required this.icon,
    required this.text,
    this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150, // Smaller width
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromRGBO(106, 79, 153, 1), size: 40),
          Column(
            children: [
              // Purple icon
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color.fromRGBO(106, 79, 153, 1),
                  fontSize: 11,
                ),
              ),
              if (buttonLabel != null)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(106, 79, 153, 0.3),
                  ),
                  child: Text(
                    buttonLabel!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final ValueNotifier<int> currentPage;

  const _PageIndicator({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentPage,
      builder: (context, index, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (i) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index
                    ? const Color.fromRGBO(106, 79, 153, 1)
                    : Colors.grey[300],
              ),
            );
          }),
        );
      },
    );
  }
}
