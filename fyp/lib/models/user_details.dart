class UserDetails {
  String user;
  String authToken;
  String userName;
  String waterGoal;
  String selectedMonth;
  String selectedDay;
  String selectedYear;
  String height;
  String currentWeight;
  String targetWeight;
  Set<String> selectedSubGoals;
  Set<int> selectedHabits;
  String activityLevels; // Stored as raw JSON string
  String scheduleIcons;  // Stored as raw JSON string
  Map<String, bool> healthConcerns;
  String levels;         // Stored as raw JSON string
  String options;        // Stored as raw JSON string
  String mealOptions;    // Stored as raw JSON string
  String waterOptions;   // Stored as raw JSON string
  Map<String, dynamic> restrictions;
  Map<String, dynamic> eatingStyles;
  List<Map<String, dynamic>> startTimes;
  List<Map<String, dynamic>> endTimes;

  UserDetails({
    required this.user,
    required this.authToken,
    required this.userName,
    required this.selectedMonth,
    required this.selectedDay,
    required this.selectedYear,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.selectedSubGoals,
    required this.selectedHabits,
    required this.activityLevels,
    required this.scheduleIcons,
    required this.healthConcerns,
    required this.levels,
    required this.waterGoal,

    required this.options,
    required this.mealOptions,
    required this.waterOptions,
    required this.restrictions,
    required this.eatingStyles,
    required this.startTimes,
    required this.endTimes,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      user: json['user'] ?? '',
      authToken: json['authToken'] ?? '',
      userName: json['userName'] ?? '',
      selectedMonth: json['selectedMonth'] ?? '',
      selectedDay: json['selectedDay'] ?? '',
      selectedYear: json['selectedYear'] ?? '',
      height: json['height'] ?? '',
      currentWeight: json['currentWeight'] ?? '',
      targetWeight: json['targetWeight'] ?? '',
      selectedSubGoals: Set<String>.from(json['selectedSubGoals'] ?? []),
      selectedHabits: Set<int>.from((json['selectedHabits'] ?? []).map((e) => int.tryParse(e.toString()) ?? 0)),
      activityLevels: json['activityLevels'] ?? '{}',
      scheduleIcons: json['scheduleIcons'] ?? '{}',
      healthConcerns: Map<String, bool>.from(json['healthConcerns'] ?? {}),
      levels: json['levels'] ?? '{}',
      options: json['options'] ?? '{}',
      waterGoal: json['waterGoal'] ?? '',
      mealOptions: json['mealOptions'] ?? '{}',
      waterOptions: json['waterOptions'] ?? '{}',
      restrictions: Map<String, dynamic>.from(json['restrictions'] ?? {}),
      eatingStyles: Map<String, dynamic>.from(json['eatingStyles'] ?? {}),
      startTimes: List<Map<String, dynamic>>.from(
        (json['startTimes'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
      endTimes: List<Map<String, dynamic>>.from(
        (json['endTimes'] ?? []).map((e) => Map<String, dynamic>.from(e)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'authToken': authToken,
      'userName': userName,
      'selectedMonth': selectedMonth,
      'selectedDay': selectedDay,
      'selectedYear': selectedYear,
      'height': height,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'selectedSubGoals': selectedSubGoals.toList(),
      'selectedHabits': selectedHabits.toList(),
      'activityLevels': activityLevels,
      'scheduleIcons': scheduleIcons,
      'healthConcerns': healthConcerns,
      'levels': levels,
      'options': options,
      'mealOptions': mealOptions,
      'waterOptions': waterOptions,
      'restrictions': restrictions,
      'eatingStyles': eatingStyles,
      'startTimes': startTimes,
      'endTimes': endTimes,
      'waterGoal': waterGoal
    };
  }
}
