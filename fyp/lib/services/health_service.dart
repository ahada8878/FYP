import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HealthService {
  final Health _health = Health();

  /// Fetches the total steps for today (midnight to now).
  Future<int> fetchTodaySteps({
    Future<bool> Function()? onUserPermissionConfirmation,
    Future<bool> Function()? onAppInstallConfirmation,
  }) async {
    
    // 1. Android: Check if Health Connect is installed
    if (Platform.isAndroid) {
      final status = await _health.getHealthConnectSdkStatus();
      if (status == HealthConnectSdkStatus.sdkUnavailable || 
          status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        
        if (onAppInstallConfirmation != null) {
          final bool userWantsToInstall = await onAppInstallConfirmation();
          if (!userWantsToInstall) return 0;
        }
        
        await _health.installHealthConnect();
        return 0; 
      }
    }

    // 2. Permissions Setup
    var types = [HealthDataType.STEPS];
    
    // ✅ FIX: Check if we already have permissions
    // We only ask the user if permissions are NOT explicitly granted
    bool? hasPermissions = await _health.hasPermissions(types);
    
    if (hasPermissions != true && onUserPermissionConfirmation != null) {
       final bool userWantsToAllow = await onUserPermissionConfirmation();
       if (!userWantsToAllow) {
         return 0; // User said No to your custom dialog
       }
    }

    // 3. Request System Authorization (Internal OS check will skip if already granted)
    bool requested = await _health.requestAuthorization(types);

    if (!requested) {
      print("Health authorization denied or failed.");
      return 0;
    }

    // 4. Fetch data
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      int? steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      print("Error fetching steps: $e");
      return 0;
    }
  }

  /// Fetches steps for the last 7 days.
  Future<List<int>> fetchWeeklySteps({
    Future<bool> Function()? onUserPermissionConfirmation,
    Future<bool> Function()? onAppInstallConfirmation,
  }) async {
    
    // 1. Android: Check Health Connect Status
    if (Platform.isAndroid) {
      final status = await _health.getHealthConnectSdkStatus();
      if (status == HealthConnectSdkStatus.sdkUnavailable || 
          status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        
        if (onAppInstallConfirmation != null) {
          final bool userWantsToInstall = await onAppInstallConfirmation();
          if (!userWantsToInstall) return List.filled(7, 0);
        }
        
        await _health.installHealthConnect();
        return List.filled(7, 0); 
      }
    }

    // 2. Permissions Setup
    var types = [HealthDataType.STEPS];
    
    // ✅ FIX: Check if we already have permissions
    bool? hasPermissions = await _health.hasPermissions(types);

    if (hasPermissions != true && onUserPermissionConfirmation != null) {
       final bool userWantsToAllow = await onUserPermissionConfirmation();
       if (!userWantsToAllow) {
         return List.filled(7, 0); 
       }
    }

    // 3. Request Authorization
    bool requested = await _health.requestAuthorization(types);
    
    if (!requested) {
      return List.filled(7, 0);
    }

    // 4. Fetch Data
    List<int> weeklySteps = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      
      try {
        int? steps = await _health.getTotalStepsInInterval(start, end);
        weeklySteps.add(steps ?? 0);
      } catch (e) {
        weeklySteps.add(0);
      }
    }
    
    return weeklySteps;
  }
}