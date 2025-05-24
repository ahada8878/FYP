import 'package:flutter/material.dart';


// 1. Updated CookingStepsSection widget with width adjustment
class CookingStepsSection extends StatelessWidget {
  final List<String> steps;
  final List<bool> completedSteps;
  final Function(int, bool) onStepToggled;

  const CookingStepsSection({
    super.key,
    required this.steps,
    required this.completedSteps,
    required this.onStepToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced horizontal padding
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.grey[50],
        margin: const EdgeInsets.symmetric( // Changed to symmetric margin
          horizontal: 8,
          vertical: 16,
        ),
        child: Container(
          width: double.infinity, // Take full available width
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Cooking Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${steps.length} steps',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.green,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                        tileColor: Colors.transparent,
                        dense: true,
                        value: completedSteps[index],
                        onChanged: (value) {
                          if (value != null) {
                            // 2. Auto-check previous steps when checking a step
                            if (value == true) {
                              // Check all steps up to and including this one
                              for (int i = 0; i <= index; i++) {
                                onStepToggled(i, true);
                              }
                            } else {
                              // Uncheck all steps from this one forward
                              for (int i = index; i < steps.length; i++) {
                                onStepToggled(i, false);
                              }
                            }
                          }
                        },
                        title: Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            decoration: completedSteps[index]
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: completedSteps[index]
                                ? Colors.grey[500]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      if (index != steps.length - 1)
                        Divider(
                          height: 24,
                          thickness: 1,
                          color: Colors.grey[200],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}