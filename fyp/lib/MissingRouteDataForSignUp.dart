import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/Registration/ActivityPage.dart';
import 'package:fyp/Registration/BadHabitsPage.dart';
import 'package:fyp/Registration/BirthdayPage.dart';
import 'package:fyp/Registration/DietryRestrictionPage.dart';
import 'package:fyp/Registration/EatingStylePage.dart';
import 'package:fyp/Registration/EatingTime.dart';
import 'package:fyp/Registration/ExperiencePage.dart';
import 'package:fyp/Registration/GoalPage.dart';
import 'package:fyp/Registration/GoalWeightPage.dart';
import 'package:fyp/Registration/HealthConcernPage.dart';
import 'package:fyp/Registration/HeightPage.dart';
import 'package:fyp/Registration/MealPerDayPage.dart';
import 'package:fyp/Registration/NamePage.dart';
import 'package:fyp/Registration/SignUpPage.dart';
import 'package:fyp/Registration/WaterIntakePage.dart';
import 'package:fyp/Registration/WeightPage.dart';
import 'package:fyp/Registration/WorkSchedulePage.dart';
import 'package:fyp/WrongThingPage.dart';
import 'package:fyp/main_navigation.dart';
import 'package:fyp/models/user_details.dart';

Widget getIncompleteStepView()  {
  final user = UserDetails(
    user: LocalDB.getUser(),
    authToken: LocalDB.getAuthToken(),
    userName: LocalDB.getUserName(),
    selectedMonth: LocalDB.getSelectedMonth(),
    selectedDay: LocalDB.getSelectedDay(),
    selectedYear: LocalDB.getSelectedYear(),
    height: LocalDB.getHeight(),
    currentWeight: LocalDB.getCurrentWeight(),
    targetWeight: LocalDB.getTargetWeight(),
    selectedSubGoals: LocalDB.getSelectedSubGoals(),
    selectedHabits: LocalDB.getSelectedHabits(),
    activityLevels: LocalDB.getActivityLevels(),
    scheduleIcons: LocalDB.getScheduleIcons(),
    healthConcerns: LocalDB.getHealthConcerns(),
    levels: LocalDB.getLevels(),
    options: LocalDB.getOptions(),
    mealOptions: LocalDB.getMealOptions(),
    waterOptions: LocalDB.getWaterOptions(),
    restrictions: LocalDB.getRestrictions(),
    eatingStyles: LocalDB.getEatingStyles(),
    startTimes: LocalDB.getStartTimes(),
    endTimes: LocalDB.getEndTimes(),
  );

  // Check each step in the order they should be filled
  if (user.authToken.isEmpty) return const CreativeSignupPage();
  if (user.userName.isEmpty) return const NamePage();
  if (user.selectedMonth.isEmpty || user.selectedDay.isEmpty || user.selectedYear.isEmpty) {
    return const BirthdayPage();
  }
  if (user.height.isEmpty) return const HeightPage();
  if (user.currentWeight.isEmpty) return const WeightPage();

  double currentWeight = extractWeightValue(user.currentWeight);
  if (user.targetWeight.isEmpty) {
    return GoalWeightPage(isEditing: false, currentWeight: currentWeight);
  }

  if (user.selectedSubGoals.isEmpty) return const GoalPage();
  if (user.selectedHabits.isEmpty) return const BadHabitsPage();
  if (user.activityLevels.isEmpty) return const ActivityPage();
  if (user.scheduleIcons.isEmpty) return const WorkSchedulePage();
  if (user.healthConcerns.isEmpty) return const HealthConcernsPage();
  if (user.levels.isEmpty) return const WeightLossFamiliarityPage();
  if (user.options.isEmpty) return const PostMealRegretPage(); 
  if (user.mealOptions.isEmpty) return const MealsPerDayPage();
  if (user.waterOptions.isEmpty) return const WaterIntakePage(); 
  if (user.restrictions.isEmpty) return const DietaryRestrictionsPage(); 
  if (user.eatingStyles.isEmpty) return const EatingStylePage(); 
  if (user.startTimes.isEmpty || user.endTimes.isEmpty) return const MealTimingPage();

  return const  MainNavigationWrapper(); 
}

double extractWeightValue(String weightString) {
  final numericPart = RegExp(r'\\d+(\\.\\d+)?').firstMatch(weightString);
  if (numericPart != null) {
    return double.tryParse(numericPart.group(0)!) ?? 0.0;
  }
  return 0.0;
}
