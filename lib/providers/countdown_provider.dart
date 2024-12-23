import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountdownProvider extends ChangeNotifier {
  Timer? _timer;
  Duration remainingTime = Duration.zero;
  String? activeParkingSpaceID;
  String? activeUserID; // Track the user who started the countdown

  // Add SharedPreferences fields
  static const String _timeKey = 'countdown_time';
  static const String _spaceKey = 'parking_space_id';
  static const String _userKey = 'user_id';
  static const String _isCountingKey = 'is_counting';

  // Initialize with loadState
  CountdownProvider() {
    loadState();
  }

  // Save state when countdown changes
  void _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeKey, remainingTime.inSeconds);
    await prefs.setString(_spaceKey, activeParkingSpaceID ?? '');
    await prefs.setString(_userKey, activeUserID ?? '');
    await prefs.setBool(_isCountingKey, _timer != null);
  }

  // Load saved state
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_timeKey);
    final spaceId = prefs.getString(_spaceKey);
    final userId = prefs.getString(_userKey);
    final isCounting = prefs.getBool(_isCountingKey) ?? false;

    if (seconds != null && spaceId != null && userId != null && isCounting) {
      remainingTime = Duration(seconds: seconds);
      activeParkingSpaceID = spaceId;
      activeUserID = userId;
      _startTimer();
    }
  }

  bool get isCountingDown => _timer != null;

  void startCountdown(int minutes, String parkingSpaceID, String userID) async {
    remainingTime = const Duration(seconds: 30);
    activeParkingSpaceID = parkingSpaceID;
    activeUserID = userID;

    // Save state to SharedPreferences
    _saveState();

    _startTimer();
  }

  void stopCountdown() async {
    _timer?.cancel();
    _timer = null;
    
    // Store the parking space ID before clearing it
    final spaceToUnlock = activeParkingSpaceID;
    
    activeParkingSpaceID = null;
    activeUserID = null;

    // Clear SharedPreferences
    _saveState();
    
    // Unlock the parking space if there was an active one
    if (spaceToUnlock != null) {
      await ApiService.unlockParkingSpace(spaceToUnlock);
      await ApiService.updatePremiumParkingStatus(spaceToUnlock, false);
    }
    
    notifyListeners();
  }

  Future<void> checkAndRestoreCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = prefs.getInt('countdown_end_time');
    final parkingSpaceID = prefs.getString('parking_space_id');
    final userID = prefs.getString('active_user_id');

    if (endTime != null && parkingSpaceID != null && userID != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = endTime - now;

      if (remaining > 0) {
        remainingTime = Duration(milliseconds: remaining);
        activeParkingSpaceID = parkingSpaceID;
        activeUserID = userID;
        _startTimer();
      } else {
        // Countdown has ended, clean up
        stopCountdown();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingTime.inSeconds > 0) {
        remainingTime -= const Duration(seconds: 1);
        _saveState();
        notifyListeners();
      } else {
        // Make sure to unlock the space when timer reaches zero
        final spaceToUnlock = activeParkingSpaceID;
        if (spaceToUnlock != null) {
          try {
            await ApiService.unlockParkingSpace(spaceToUnlock);
            await ApiService.updatePremiumParkingStatus(spaceToUnlock, false);
            print('Successfully unlocked space: $spaceToUnlock');
          } catch (e) {
            print('Error unlocking space: $e');
          }
        }
        stopCountdown();
      }
    });
    notifyListeners();
  }

  void restoreCountdown(int remainingSeconds, String parkingSpaceId, String userId) {
    remainingTime = const Duration(seconds: 30);
    activeParkingSpaceID = parkingSpaceId;
    activeUserID = userId;
    _startTimer();
    notifyListeners();
  }
}
