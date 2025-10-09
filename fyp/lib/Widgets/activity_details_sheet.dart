import 'package:flutter/material.dart';
import 'package:fyp/Widgets/activity_log_sheet.dart';
import 'package:fyp/calorie_tracker_controller.dart';
import 'package:fyp/models/activity_model.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';
import '../services/reward_service.dart';

class ActivityDetailsSheet extends StatefulWidget {
  final Activity activity;
  const ActivityDetailsSheet({super.key, required this.activity});

  @override
  State<ActivityDetailsSheet> createState() => _ActivityDetailsSheetState();
}

class _ActivityDetailsSheetState extends State<ActivityDetailsSheet> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _durationController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // In ActivityDetailsSheet class
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Close current sheet and reopen ActivityLogSheet
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ActivityLogSheet(),
                  );
                },
              ),
              Expanded(
                child: Text(
                  widget.activity.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero, // Add this to prevent overflow
                constraints:
                    const BoxConstraints(), // Add this to prevent overflow
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Log your workout time",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.center,
            child: Text(
              "Calories burned will be calculated based on the duration",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text("Select Date"),
            trailing: Text(
              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
            ),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Duration (minutes)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final duration = int.tryParse(_durationController.text);
                if (duration != null) {
                  // 1. Log the activity to the backend
                  final activityService = ActivityService();
                  final calories = widget.activity.caloriesPerMin * duration;
                  await activityService.logActivity(
                    activityType: widget.activity.name,
                    duration: duration,
                    caloriesBurned: calories.toDouble(),
                  );

                  // 2. Check for new rewards
                  final rewardService = RewardService();
                  await rewardService.checkAndUnlockRewards();

                  // Update the local tracker and close the sheet
                  final tracker = Provider.of<CalorieTrackerController>(context,
                      listen: false);
                  tracker.addBurnedCalories(calories);
                  tracker.updateLatestActivity(
                    widget.activity.name,
                    duration,
                    calories,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Log Activity",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
