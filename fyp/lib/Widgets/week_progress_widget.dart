import 'package:flutter/material.dart';

class WeekProgressWidget extends StatelessWidget {
  final int completedDays;

  const WeekProgressWidget({
    super.key, 
    required this.completedDays
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Week 1',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121))),
            const Text('Every meal counts. Stay strong!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (index) {
                final day = index + 1;
                final isCircleFilled = day <= completedDays;
                final isLineFilled = day < completedDays;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CircleAvatar(
                              radius: 6,
                              backgroundColor: isCircleFilled
                                  ? const Color.fromRGBO(106, 79, 153, 1)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          if (index != 6)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isLineFilled
                                    ? const Color.fromRGBO(106, 79, 153, 1)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Day $day',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF9E9E9E))),
                    ],
                  ),
                );
              }),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Recommendation Source',
                    style: TextStyle(
                        fontSize: 12, color: Color.fromRGBO(106, 79, 153, 1))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}