import 'package:flutter/material.dart';
import 'package:fyp/water_tracker_controller.dart';
import 'package:provider/provider.dart';

class WaterTracker extends StatelessWidget {
  const WaterTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final waterController = Provider.of<WaterTrackerController>(context);
    final currentGlasses = waterController.filledGlasses;
    final currentLiters = currentGlasses * 0.2;
    const totalLiters = 2.00;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Water Tracker',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${currentLiters.toStringAsFixed(2)} / ${totalLiters.toStringAsFixed(2)} L',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color.fromRGBO(106, 79, 153, 1),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        _buildGlassGrid(waterController, currentGlasses),
      ],
    );
  }

  Widget _buildGlassGrid(WaterTrackerController controller, int filledGlasses) {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(12, (index) => _buildWaterGlass(index, filledGlasses, controller)),
        ),
      ),
    );
  }

  Widget _buildWaterGlass(int index, int filledGlasses, WaterTrackerController controller) {
    final isFilled = index < filledGlasses;
    
    return GestureDetector(
      onTap: () => controller.updateGlasses(index + 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isFilled ? const Color.fromRGBO(106, 79, 153, 0.5) : Colors.transparent,
          border: Border.all(
            color: const Color.fromRGBO(106, 79, 153, 1),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            Icons.local_drink,
            color: isFilled ? Colors.white : const Color.fromRGBO(106, 79, 153, 1),
            size: 24,
          ),
        ),
      ),
    );
  }
}