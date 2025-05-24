import 'package:flutter/material.dart';

class Activity {
  final String name;
  final int caloriesPerMin;
  final IconData icon;

  const Activity(this.name, this.caloriesPerMin, this.icon);
}

class ActivityData {
  static final Map<String, List<Activity>> activities = {
    'A': [
      const Activity('Active Games with Friends', 5, Icons.sports_esports),
      const Activity('Active Work Tasks', 4, Icons.work),
    ],
    'B': [
      const Activity('Basketball', 5, Icons.sports_basketball),
      const Activity('Biking', 5, Icons.directions_bike),
    ],
    'C': [
      const Activity('Car Washing', 3, Icons.car_repair),
      const Activity('Cardio', 4, Icons.directions_run),
      const Activity('Climbing', 6, Icons.landscape),
    ],
    'D': [
      const Activity('Dancing', 4, Icons.music_note),
      const Activity('Dodgeball', 5, Icons.sports_baseball),
    ],
    'E': [
      const Activity('Elliptical', 5, Icons.directions_walk),
      const Activity('Exercise Class', 4, Icons.group),
    ],
    'F': [
      const Activity('Football', 6, Icons.sports_football),
      const Activity('Frisbee', 3, Icons.outdoor_grill),
    ],
    'G': [
      const Activity('Gardening', 3, Icons.nature),
      const Activity('Golf', 3, Icons.golf_course),
    ],
    'H': [
      const Activity('Hiking', 6, Icons.terrain),
      const Activity('House Cleaning', 3, Icons.cleaning_services),
    ],
    'I': [
      const Activity('Ice Skating', 4, Icons.ac_unit),
      const Activity('Indoor Cycling', 5, Icons.pedal_bike),
    ],
    'J': [
      const Activity('Jump Rope', 6, Icons.fitness_center),
      const Activity('Jogging', 5, Icons.directions_run),
    ],
    'K': [
      const Activity('Kickboxing', 7, Icons.sports_martial_arts),
      const Activity('Kayaking', 4, Icons.directions_boat),
    ],
    'L': [
      const Activity('Lawn Mowing', 3, Icons.grass),
      const Activity('Lacrosse', 6, Icons.sports_volleyball),
    ],
    'M': [
      const Activity('Martial Arts', 6, Icons.sports_kabaddi),
      const Activity('Mountain Climbing', 7, Icons.terrain),
    ],
    'N': [
      const Activity('Netball', 5, Icons.sports_volleyball),
      const Activity('Nordic Walking', 4, Icons.directions_walk),
    ],
    'O': [
      const Activity('Outdoor Swimming', 5, Icons.pool),
      const Activity('Obstacle Course', 6, Icons.emoji_events),
    ],
    'P': [
      const Activity('Pilates', 4, Icons.self_improvement),
      const Activity('Push-Ups', 5, Icons.accessibility_new),
    ],
    'Q': [
      const Activity('Quick Yoga', 3, Icons.self_improvement),
      const Activity('Quidditch', 6, Icons.sports_baseball),
    ],
    'R': [
      const Activity('Rowing', 5, Icons.directions_boat),
      const Activity('Rock Climbing', 7, Icons.landscape),
    ],
    'S': [
      const Activity('Swimming', 5, Icons.pool),
      const Activity('Skiing', 6, Icons.downhill_skiing),
    ],
    'T': [
      const Activity('Tennis', 5, Icons.sports_tennis),
      const Activity('Tai Chi', 4, Icons.self_improvement),
    ],
    'U': [
      const Activity('Ultimate Frisbee', 5, Icons.outdoor_grill),
      const Activity('Underwater Hockey', 6, Icons.water),
    ],
    'V': [
      const Activity('Volleyball', 5, Icons.sports_volleyball),
      const Activity('Vigorous Cleaning', 3, Icons.cleaning_services),
    ],
    'W': [
      const Activity('Weightlifting', 6, Icons.fitness_center),
      const Activity('Walking', 3, Icons.directions_walk),
    ],
    'X': [
      const Activity('Xtreme Sports', 7, Icons.emergency),
      const Activity('X-Country Skiing', 6, Icons.downhill_skiing),
    ],
    'Y': [
      const Activity('Yoga', 3, Icons.self_improvement),
      const Activity('Yard Work', 4, Icons.nature),
    ],
    'Z': [
      const Activity('Zumba', 5, Icons.music_note),
      const Activity('Zen Meditation', 3, Icons.self_improvement),
    ],
  };
}