import 'package:flutter/material.dart';
import 'package:fyp/water_tracker_controller.dart';
import 'package:provider/provider.dart';

void showLogWaterOverlay(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LogWaterOverlayContent(),
  );
}

class _LogWaterOverlayContent extends StatefulWidget {
  @override
  State<_LogWaterOverlayContent> createState() =>
      _LogWaterOverlayContentState();
}

class _LogWaterOverlayContentState extends State<_LogWaterOverlayContent> {
  double _waterAmount = 0.0;
  final double _dailyGoal = 2000.0;
  final double _stepSize = 200.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Log Water',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(4),
                  backgroundColor: Colors.black,
                ),
                onPressed: () => _adjustWater(-_stepSize),
                child: const Icon(Icons.remove, color: Colors.white),
              ),
              const SizedBox(width: 32),
              const Icon(Icons.local_drink, size: 48, color: Colors.blue),
              const SizedBox(width: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(4),
                  backgroundColor: Colors.black,
                ),
                onPressed: () => _adjustWater(_stepSize),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_waterAmount.toStringAsFixed(0)} mL',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Daily goal: ${(_dailyGoal / 1000).toStringAsFixed(2)} Litres',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _waterAmount > 0 ? _saveWater : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _waterAmount > 0 ? Colors.black : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _adjustWater(double amount) {
    setState(() {
      _waterAmount = (_waterAmount + amount).clamp(0.0, _dailyGoal);
    });
  }

  void _saveWater() {
    final waterController =
        Provider.of<WaterTrackerController>(context, listen: false);
    final glassesToAdd = (_waterAmount / 200).floor(); // Convert ml to glasses
    waterController.addWater(_waterAmount);
    Navigator.pop(context);
  }
}
