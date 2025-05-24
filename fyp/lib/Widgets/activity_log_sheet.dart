import 'package:flutter/material.dart';
import 'package:fyp/Widgets/activity_details_sheet.dart';
import 'package:fyp/models/activity_model.dart';

class ActivityLogSheet extends StatelessWidget {
  const ActivityLogSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                for (final entry in ActivityData.activities.entries)
                  if (entry.value.isNotEmpty)
                    _buildActivityGroup(context, entry.key, entry.value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        const Text(
          'Log Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildActivityGroup(BuildContext context, String letter, List<Activity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            letter,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        ...activities.map((activity) => ListTile(
          leading: Icon(activity.icon, color: const Color.fromRGBO(106, 79, 153, 1)),
          title: Text(activity.name),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
          onTap: () => _handleActivitySelect(context, activity),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  void _handleActivitySelect(BuildContext context, Activity activity) {
  Navigator.pop(context); // Close the first bottom sheet
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ActivityDetailsSheet(activity: activity),
  );
}
}