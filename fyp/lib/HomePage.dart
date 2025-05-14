import 'package:flutter/material.dart';
import 'loginpage.dart';

class CreativeHomePage extends StatefulWidget {
  final String userName;
  final String userGoal;

  const CreativeHomePage({
    Key? key,
    required this.userName,
    required this.userGoal,
  }) : super(key: key);

  @override
  State<CreativeHomePage> createState() => _CreativeHomePageState();
}

class _CreativeHomePageState extends State<CreativeHomePage> {
  final List<Map<String, dynamic>> motivationalQuotes = [
    {'quote': 'You are stronger than you think.', 'author': 'Unknown'},
    {'quote': 'Progress, not perfection.', 'author': 'Kim Collins'},
    {'quote': 'One step at a time.', 'author': 'Unknown'},
    {'quote': 'Believe in yourself.', 'author': 'Anonymous'},
  ];

  final List<Map<String, dynamic>> recommendedActivities = [
    {'image': '🥗', 'title': 'Healthy Eating'},
    {'image': '🏋️', 'title': 'Strength Training'},
    {'image': '🧘', 'title': 'Mindfulness'},
  ];

  final List<Map<String, dynamic>> weeklyTasks = [
    {'task': 'Walk 10,000 steps', 'progress': 0.7},
    {'task': 'Eat 3 servings of vegetables', 'progress': 0.5},
    {'task': 'Drink 8 glasses of water', 'progress': 0.9},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${widget.userName}!"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Goal Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Your Goal: ${widget.userGoal}",
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Motivational Quotes Section
            Text(
              "Motivation for Today",
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: motivationalQuotes.length,
                itemBuilder: (context, index) {
                  final quote = motivationalQuotes[index];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"${quote['quote']}"',
                          style: textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '- ${quote['author']}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Recommended Activities Section
            Text(
              "Recommended for You",
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: recommendedActivities.map((activity) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(activity['image'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          activity['title'],
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Weekly Task Progress Section
            Text(
              "Weekly Tasks",
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: weeklyTasks.length,
              itemBuilder: (context, index) {
                final task = weeklyTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['task'],
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: task['progress'],
                            backgroundColor: colorScheme.surfaceVariant,
                            color: colorScheme.primary,
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
