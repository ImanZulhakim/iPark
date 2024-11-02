import 'dart:async';
import 'package:flutter/material.dart';

class CountdownProvider with ChangeNotifier {
  Timer? _timer;
  Duration remainingTime = Duration.zero;
  String? activeParkingSpaceID;
  String? activeUserID; // Track the user who started the countdown

  bool get isCountingDown => _timer != null;

  void startCountdown(int minutes, String parkingSpaceID, String userID) {
    remainingTime = Duration(minutes: minutes);
    activeParkingSpaceID = parkingSpaceID;
    activeUserID = userID; // Set the active userID

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds > 0) {
        remainingTime -= Duration(seconds: 1);
        notifyListeners();
      } else {
        _timer?.cancel();
        _timer = null;
        notifyListeners();
      }
    });
  }

  void stopCountdown() {
    _timer?.cancel();
    _timer = null;
    activeParkingSpaceID = null;
    activeUserID = null; // Reset the userID when countdown stops
    notifyListeners();
  }
}
