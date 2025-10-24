// lib/services/reward_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config_service.dart';
import '../models/reward_definitions.dart'; // Import the centralized reward definitions
import '../Widgets/reward_card.dart';       // Import the Reward model

class RewardService {
  /// The base URL for the API, constructed from a configuration file.
  final String baseUrl = '$baseURL/api';

  /// Fetches all possible rewards and sets their 'achieved' status based on the user's progress.
  /// This function retrieves the list of rewards the user has unlocked from the backend.
  /// It then compares this list against a complete, predefined list of all possible rewards
  /// to return a final list for the UI, with each reward correctly marked as achieved or not.
  Future<List<Reward>> getRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Retrieve the authentication token.

    print('token: $token'); // Debugging line to check the token value.

    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/rewards'), // The endpoint for fetching user-specific rewards.
      headers: {
        'x-auth-token': token,       // ✅ FIX: The header value should ONLY be the token.
      },
    );

    if (response.statusCode == 200) {
      // Decode the JSON data from the backend.
      final List<dynamic> unlockedRewardsData = json.decode(response.body);

      // Create a Set of names of the rewards the user has unlocked for efficient lookup.
      // The backend response contains a 'name' key for each reward.
      final Set<String> unlockedRewardNames = unlockedRewardsData
          .map((json) => json['name'] as String)
          .toSet();

      // Map over the master list of all possible reward definitions.
      return allRewardDefinitions.entries.map((entry) {
        final rewardName = entry.key;
        final rewardTemplate = entry.value;
        final bool isUnlocked = unlockedRewardNames.contains(rewardName);

        // Return a new Reward object, copying the static data from the definition
        // and setting the dynamic 'achieved' status based on the backend data.
        return Reward(
          title: rewardTemplate.title,
          description: rewardTemplate.description,
          icon: rewardTemplate.icon,
          achieved: isUnlocked, 
          category: rewardTemplate.category,
        );
      }).toList();
    } else {
      // If the server response is not successful, throw an exception.
      throw Exception('Failed to load rewards');
    }
  }

  /// Sends a request to the backend to check for and unlock any new rewards.
  ///
  /// This should be called after a user completes a relevant action, like logging an activity.
  Future<void> checkAndUnlockRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Retrieve the authentication token.
    final checkUrl = Uri.parse('$baseUrl/rewards/check'); // The endpoint for checking rewards.

    // Make a POST request to trigger the reward check logic on the server.
    await http.post( 
      checkUrl,
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '', // The request is authenticated.
      },
    );
  }
}