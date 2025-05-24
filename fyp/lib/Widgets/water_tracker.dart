import 'package:flutter/material.dart';

class WaterTracker extends StatefulWidget {
  const WaterTracker({super.key});

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  int _maxIndex = -1; // Tracks the highest selected glass index
  final double _glassCapacity = 0.20; // Each glass holds 0.20L
  final int _totalGlasses = 12; // 12 glasses total

  @override
  Widget build(BuildContext context) {
    final currentLiters = (_maxIndex + 1) * _glassCapacity;
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
        _buildGlassGrid(),
      ],
    );
  }

  Widget _buildGlassGrid() {
    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_totalGlasses, (index) => _buildWaterGlass(index)),
        ),
      ),
    );
  }

  Widget _buildWaterGlass(int index) {
    final isFilled = index <= _maxIndex;
    
    return GestureDetector(
      onTap: () => _handleGlassTap(index),
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

  void _handleGlassTap(int index) {
    setState(() {
      if (index > _maxIndex) {
        // Select this glass and all previous ones
        _maxIndex = index;
      } else {
        // Unselect this glass and all subsequent ones
        _maxIndex = index - 1;
      }
    });
  }
}