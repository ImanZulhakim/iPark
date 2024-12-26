import 'package:flutter/material.dart';
import 'package:iprsr/services/api_service.dart';

class LocationProvider with ChangeNotifier {
  Map<String, String>? _selectedLocation;
  List<Map<String, dynamic>> _locations = [];
  String? _currentState;
  String? _currentDistrict;
  bool _isLoading = true;

  Map<String, String>? get selectedLocation => _selectedLocation;
  List<Map<String, dynamic>> get locations => _locations;
  String? get currentState => _currentState;
  String? get currentDistrict => _currentDistrict;
  bool get isLoading => _isLoading;

  void selectLocation(Map<String, String> location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void selectState(String? state) {
    _currentState = state;
    _currentDistrict = null; // Reset district when state changes
    notifyListeners();
  }

  void selectDistrict(String? district) {
    _currentDistrict = district;
    notifyListeners();
  }

  // Reset the state and district selections
  void resetSelections() {
    _currentState = null;
    _currentDistrict = null;
    notifyListeners();
  }

  Future<void> fetchLocations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.getParkingLocation();
      if (response['status'] == 'success') {
        _locations = List<Map<String, dynamic>>.from(response['data']);
      } else {
        _locations = [];
      }
    } catch (e) {
      _locations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLastUsedLot(String userID) async {
  try {
    print('Fetching last used lot for userID: $userID');
    final lastUsedLotID = await ApiService.getLastUsedLotID(userID);
    print('Last used lot ID: $lastUsedLotID');
    if (lastUsedLotID != null) {
      final lotName = await ApiService.getLotName(lastUsedLotID);
      print('Lot name: $lotName');
      if (lotName != null) {
        _selectedLocation = {
          'lotID': lastUsedLotID,
          'lot_name': lotName,
        };
        notifyListeners();
      }
    } else {
      print('last_used_lotID is null for userID: $userID');
      _selectedLocation = {
        'lotID': 'DefaultLotID',
        'lot_name': 'DefaultLotName',
      };
      notifyListeners();
    }
  } catch (e) {
    print('Error fetching last_used_lotID: $e');
    _selectedLocation = {
      'lotID': 'DefaultLotID',
      'lot_name': 'DefaultLotName',
    };
    notifyListeners();
  }
}

Future<void> updateLastUsedLot(String userID, String lotID) async {
  print('Updating last used lot for userID: $userID with lotID: $lotID');
  await ApiService.updateLastUsedLotID(userID, lotID);
}


}