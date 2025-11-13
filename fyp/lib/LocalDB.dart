import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> clear() async {
    // Ensure _prefs is initialized before trying to use it.
    if (_prefs == null) {
      await init(); // Initialize if not already
    }
    await _prefs!.clear();
  }
  
  /// -- Auth Token --
static Future<void> setAuthToken(String token) async {
  await _prefs?.setString('authToken', token);
}

static Future<void> setUserEmail(String token) async {
  await _prefs?.setString('email', token);
}


static String getAuthToken() {
  return _prefs?.getString('authToken') ?? '';
}

static String getUserEmail() {
  return _prefs?.getString('email') ?? '';
}

static Future<void> setOTP(String token) async {
  await _prefs?.setString('OTP', token);
}

static String getOTP() {
  return _prefs?.getString('OTP') ?? '';
}

static Future<void> setUser(String user) async {
  await _prefs?.setString('user', user);
}

static String getUser() {
  return _prefs?.getString('user') ?? '';
}

static int getCarbs() {
  // Use getInt() for retrieving integers.
  // The null-aware operator (??) provides the default value (0) if the key isn't found.
  return _prefs?.getInt('carbs') ?? 0;
}

// Make sure to use the correct return type: 'int'
static int getProtein() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('protein') ?? 0;
}

// Make sure to use the correct return type: 'int'
static int getFats() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('fat') ?? 0; // Keeping your original 45 default for fat
}

static int getConsumedCalories() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('consumedCalories') ?? 0; // Keeping your original 45 default for fat
}

static int getGoalCalories() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('goalCalories') ?? 0; // Keeping your original 45 default for fat
}

static int getSteps() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('steps') ?? 0; // Keeping your original 45 default for fat
}

static int getStepsGoal() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('stepsGoal') ?? 0; // Keeping your original 45 default for fat
}



static int getWaterGoal() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('waterGoal') ?? 0; // Keeping your original 45 default for fat
}

static int getWaterConsumed() {
  // Use getInt() for retrieving integers.
  return _prefs?.getInt('waterConsumed') ?? 0; // Keeping your original 45 default for fat
}


static Future<void> setWaterGoal(int name) async {
  await _prefs?.setInt('waterGoal', name);
}

static Future<void> setWaterConsumed(int name) async {
  await _prefs?.setInt('waterConsumed', name);
}


static Future<void> setSteps(int name) async {
  await _prefs?.setInt('steps', name);
}


static Future<void> setStepsGoal(int name) async {
  await _prefs?.setInt('stepsGoal', name);
}



 /// -- User Name --
static Future<void> setUserName(String name) async {
  await _prefs?.setString('userName', name);
}



static String getUserName() {
  return _prefs?.getString('userName') ?? '';
}

static Future<void> setConsumedCalories(int name) async {
  await _prefs?.setInt('consumedCalories', name);
}

static Future<void> setGoalCalories(int name) async {
  await _prefs?.setInt('goalCalories', name);
}

static Future<void> setCarbs(int name) async {
  await _prefs?.setInt('carbs', name);
}

static Future<void> setProtein(int name) async {
  await _prefs?.setInt('protein', name);
}

static Future<void> setFats(int name) async {
  await _prefs?.setInt('fat', name);
}

  /// -- Simple Strings --
  static Future<void> setSelectedMonth(String month) async =>
      await _prefs?.setString('selectedMonth', month);
  static String getSelectedMonth() => _prefs?.getString('selectedMonth') ?? '';

  static Future<void> setSelectedDay(String day) async =>
      await _prefs?.setString('selectedDay', day);
  static String getSelectedDay() => _prefs?.getString('selectedDay') ?? '';

  static Future<void> setSelectedYear(String year) async =>
      await _prefs?.setString('selectedYear', year);
  static String getSelectedYear() => _prefs?.getString('selectedYear') ?? '';

  static Future<void> setHeight(String height) async =>
      await _prefs?.setString('height', height);
  static String getHeight() => _prefs?.getString('height') ?? '';



  static Future<void> setCurrentWeight(String weight) async =>
      await _prefs?.setString('currentWeight', weight);
  static String getCurrentWeight() => _prefs?.getString('currentWeight') ?? '0';


  static Future<void> setStartWeight(String weight) async =>
      await _prefs?.setString('startWeight', weight);
  static String getStartWeight() => _prefs?.getString('startWeight') ?? '0';


  static Future<void> setTargetWeight(String weight) async =>
      await _prefs?.setString('targetWeight', weight);
  static String getTargetWeight() => _prefs?.getString('targetWeight') ?? '';

  /// -- Collections --
  static Future<void> setSelectedSubGoals(Set<String> subGoals) async =>
      await _prefs?.setStringList('selectedSubGoals', subGoals.toList());
  static Set<String> getSelectedSubGoals() =>
      _prefs?.getStringList('selectedSubGoals')?.toSet() ?? {};

  static Future<void> setSelectedHabits(Set<int> habits) async =>
      await _prefs?.setStringList(
        'selectedHabits',
        habits.map((e) => e.toString()).toList(),
      );
  static Set<int> getSelectedHabits() =>
      _prefs
          ?.getStringList('selectedHabits')
          ?.map(int.parse)
          .toSet() ??
      {};

  /// -- Dynamic Maps (via JSON) --
  static Future<void> setActivityLevels(String map) async =>
      await _prefs?.setString('activityLevels',map);
  static String getActivityLevels() {
    final string = _prefs?.getString('activityLevels');
    if (string == null) return '';
    return string;
  }

  static Future<void> setScheduleIcons(String map) async =>
      await _prefs?.setString('scheduleIcons', map);
  static String getScheduleIcons() {
    final string = _prefs?.getString('scheduleIcons');
    if (string == null) return '';
    return string;
  }

  static Future<void> setHealthConcerns(Map<String, bool> map) async =>
      await _prefs?.setString('healthConcerns', jsonEncode(map));
  static Map<String, bool> getHealthConcerns() {
    final jsonString = _prefs?.getString('healthConcerns');
    if (jsonString == null) return {};
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as bool));
  }

  static Future<void> setLevels(String map) async =>
      await _prefs?.setString('levels', map);
  static String getLevels() {
    final string = _prefs?.getString('levels');
    if (string == null) return '';
    return string;
  }

  static Future<void> setOptions(String map) async =>
      await _prefs?.setString('options', map);
  static String getOptions() {
    final string = _prefs?.getString('options');
    if (string == null) return '';
    return string;
  }

  static Future<void> setMealOptions(String map) async =>
      await _prefs?.setString('mealOptions', map);
  static String getMealOptions() {
    final string = _prefs?.getString('mealOptions');
    if (string == null) return '';
    return string;
  }

  static Future<void> setWaterOptions(String map) async =>
      await _prefs?.setString('waterOptions', map);
  static String getWaterOptions() {
    final string = _prefs?.getString('waterOptions');
    if (string == null) return '';
    return string;
  }

  static Future<void> setRestrictions(Map<String, dynamic> map) async =>
      await _prefs?.setString('restrictions', jsonEncode(map));
  static Map<String, dynamic> getRestrictions() {
    final jsonString = _prefs?.getString('restrictions');
    if (jsonString == null) return {};
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static Future<void> setEatingStyles(Map<String, dynamic> map) async =>
      await _prefs?.setString('eatingStyles', jsonEncode(map));
  static Map<String, dynamic> getEatingStyles() {
    final jsonString = _prefs?.getString('eatingStyles');
    if (jsonString == null) return {};
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

 /// -- Start Times --
static Future<void> setStartTimes(List<Map<String, dynamic>> list) async {
  await _prefs?.setString('startTimes', jsonEncode(list));
}

static List<Map<String, dynamic>> getStartTimes() {
  final jsonString = _prefs?.getString('startTimes');
  if (jsonString == null) return [];

  final decoded = jsonDecode(jsonString);
  if (decoded is List) {
    return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

  return [];
}

/// -- End Times --
static Future<void> setEndTimes(List<Map<String, dynamic>> list) async {
  await _prefs?.setString('endTimes', jsonEncode(list));
}

static List<Map<String, dynamic>> getEndTimes() {
  final jsonString = _prefs?.getString('endTimes');
  if (jsonString == null) return [];

  final decoded = jsonDecode(jsonString);
  if (decoded is List) {
    return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

  return [];
}











}
