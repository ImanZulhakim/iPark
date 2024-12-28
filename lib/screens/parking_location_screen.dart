import 'package:flutter/material.dart';
import 'package:iprsr/providers/location_provider.dart';
import 'package:iprsr/screens/main_screen.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:provider/provider.dart';

class ParkingLocationScreen extends StatefulWidget {
  final String lotID;

  const ParkingLocationScreen({super.key, required this.lotID});

  @override
  _ParkingLocationScreenState createState() => _ParkingLocationScreenState();
}

class _ParkingLocationScreenState extends State<ParkingLocationScreen> {
  @override
  void initState() {
    super.initState();
    // Reset the UI state when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.resetSelections(); // Reset to start from state selection
      locationProvider.fetchLocations(); // Fetch locations again
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locationProvider.currentState == null
              ? 'Select State'
              : locationProvider.currentDistrict == null
                  ? 'Select District in ${locationProvider.currentState}'
                  : 'Select Parking Lot in ${locationProvider.currentDistrict}, ${locationProvider.currentState}',
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: _buildBody(locationProvider),
      floatingActionButton: _buildFloatingActionButton(locationProvider),
    );
  }

  Widget _buildBody(LocationProvider locationProvider) {
    if (locationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (locationProvider.locations.isEmpty) {
      return const Center(child: Text('No parking locations available'));
    }
    return _buildLocationList(locationProvider);
  }

  Widget? _buildFloatingActionButton(LocationProvider locationProvider) {
    if (locationProvider.currentState == null && locationProvider.currentDistrict == null) {
      return null;
    }
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          if (locationProvider.currentDistrict != null) {
            locationProvider.selectDistrict(null); // Reset to districts
          } else if (locationProvider.currentState != null) {
            locationProvider.selectState(null); // Reset to states
          }
        });
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(Icons.arrow_back),
    );
  }

  Widget _buildLocationList(LocationProvider locationProvider) {
    if (locationProvider.currentState == null) {
      return _buildStateList(locationProvider);
    } else if (locationProvider.currentDistrict == null) {
      return _buildDistrictList(locationProvider);
    } else {
      return _buildParkingLotList(locationProvider);
    }
  }

  Widget _buildStateList(LocationProvider locationProvider) {
    final states = locationProvider.locations.map((e) => e['state']).toList();

    return ListView.builder(
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        return _buildListCard(
          title: state,
          onTap: () => locationProvider.selectState(state),
        );
      },
    );
  }

  Widget _buildDistrictList(LocationProvider locationProvider) {
    final districts = locationProvider.locations.firstWhere(
        (loc) => loc['state'] == locationProvider.currentState)['districts'];

    return ListView.builder(
      itemCount: districts.length,
      itemBuilder: (context, index) {
        final district = districts[index]['district'];
        return _buildListCard(
          title: district,
          onTap: () => locationProvider.selectDistrict(district),
        );
      },
    );
  }

  Widget _buildParkingLotList(LocationProvider locationProvider) {
    final parkingLots = locationProvider.locations
        .firstWhere((loc) => loc['state'] == locationProvider.currentState)['districts']
        .firstWhere((d) => d['district'] == locationProvider.currentDistrict)['parking_lots'];

    return ListView.builder(
      itemCount: parkingLots.length,
      itemBuilder: (context, index) {
        final lot = parkingLots[index];
        final isSelected = widget.lotID == lot['lotID'];

        return _buildParkingLotCard(
          lot: lot,
          isSelected: isSelected,
          onTap: () async {
            if (isSelected) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have already chosen ${lot['lot_name']}'),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            final auth = Provider.of<AuthService>(context, listen: false);
            if (auth.user != null) {
              await locationProvider.updateLastUsedLot(auth.user!.userID, lot['lotID']);
            }
            try {
              locationProvider.selectLocation({
                'lotID': lot['lotID'],
                'lot_name': lot['lot_name'],
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update parking lot selection. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildListCard({required String title, required VoidCallback onTap}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color.fromARGB(255, 61, 61, 61) : Colors.white;

    return Card(
      color: cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildParkingLotCard({
    required Map<String, dynamic> lot,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color.fromARGB(255, 61, 61, 61) : Colors.white;
    final Color selectedColor = isDarkMode ? Colors.green[800]! : Colors.green[100]!;

    return Card(
      color: isSelected ? selectedColor : cardColor,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        tileColor: isSelected ? selectedColor : cardColor,
        title: Text(
          lot['lot_name'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spaces: ${lot['spaces']}'),
            Text('Type: ${toTitleCase(lot['locationType'])}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}