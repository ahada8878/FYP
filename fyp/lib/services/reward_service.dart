// lib/services/reward_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config_service.dart';
import '../models/reward_definitions.dart';
import '../Widgets/reward_card.dart';

/// A DTO to hold all gamification state
class GamificationData {
  final List<Reward> rewards;
  final int xp;
  final int coins;
  final int level;
  final List<String> newlyUnlockedIds; // To trigger animations

  GamificationData({
    required this.rewards,
    required this.xp,
    required this.coins,
    required this.level,
    this.newlyUnlockedIds = const [],
  });
}

class RewardService {
  final String baseUrl = '$baseURL/api';

  /// Fetches rewards + XP + Coins + Level
  Future<GamificationData> getGamificationData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/rewards'),
      headers: {
        'x-auth-token': token,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseResponse(data);
    } else {
      throw Exception('Failed to load gamification data');
    }
  }

  /// Checks for new rewards based on step data and unlocks them
  Future<GamificationData> checkAndUnlockRewards({
    int currentSteps = 0,
    List<int> weeklySteps = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final checkUrl = Uri.parse('$baseUrl/rewards/check');

    final response = await http.post(
      checkUrl,
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      // ✅ Send step data in the body
      body: jsonEncode({
        'currentSteps': currentSteps,
        'weeklySteps': weeklySteps,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseResponse(data);
    } else {
      print("Reward check failed: ${response.body}");
      throw Exception('Failed to check rewards');
    }
  }

  /// Helper to parse the backend JSON into our GamificationData object
  GamificationData _parseResponse(Map<String, dynamic> jsonResponse) {
    // 1. Parse Rewards List
    final List<dynamic> rewardsJson = jsonResponse['rewards'] ?? [];
    final Set<String> unlockedNames = rewardsJson
        .map((r) => r['name'] as String)
        .toSet();

    final rewardsList = allRewardDefinitions.entries.map((entry) {
      final isUnlocked = unlockedNames.contains(entry.key);
      return Reward(
        title: entry.value.title,
        description: entry.value.description,
        icon: entry.value.icon,
        achieved: isUnlocked,
        category: entry.value.category,
      );
    }).toList();

    // 2. Parse New Unlocks (if any)
    final List<dynamic> newIdsJson = jsonResponse['newlyUnlocked'] ?? [];
    final List<String> newIds = newIdsJson.map((e) => e.toString()).toList();

    return GamificationData(
      rewards: rewardsList,
      xp: jsonResponse['xp'] ?? 0,
      coins: jsonResponse['coins'] ?? 0,
      level: jsonResponse['level'] ?? 1,
      newlyUnlockedIds: newIds,
    );
  }

  /// Redeems an item from the shop. Returns updated coin balance and inventory.
  Future<Map<String, dynamic>> redeemItem(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('$baseUrl/rewards/redeem');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: json.encode({'itemId': itemId}),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      return data; // Expecting { success: true, coins: 100, inventory: [...] }
    } else {
      throw Exception(data['message'] ?? 'Redemption failed');
    }
  }

}