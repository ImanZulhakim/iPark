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
    // Fetch locations from the API when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).fetchLocations();
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
      body: locationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : locationProvider.locations.isEmpty
              ? const Center(child: Text('No parking locations available'))
              : _buildLocationList(locationProvider),
      floatingActionButton: locationProvider.currentState != null ||
              locationProvider.currentDistrict != null
          ? FloatingActionButton(
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
            )
          : null,
    );
  }

  Widget _buildLocationList(LocationProvider locationProvider) {
    if (locationProvider.currentState == null) {
      // Display list of states
      return _buildStateList(locationProvider);
    } else if (locationProvider.currentDistrict == null) {
      // Display list of districts for the selected state
      return _buildDistrictList(locationProvider);
    } else {
      // Display list of parking lots for the selected district
      return _buildParkingLotList(locationProvider);
    }
  }

  Widget _buildStateList(LocationProvider locationProvider) {
    final states = locationProvider.locations.map((e) => e['state']).toList();

    return ListView.builder(
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        return Card(
          color: Colors.white,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(
              state,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              locationProvider.selectState(state);
            },
          ),
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
        return Card(
          color: Colors.white,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(
              district,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              locationProvider.selectDistrict(district);
            },
          ),
        );
      },
    );
  }

  Widget _buildParkingLotList(LocationProvider locationProvider) {
    final parkingLots = locationProvider.locations
        .firstWhere(
            (loc) => loc['state'] == locationProvider.currentState)['districts']
        .firstWhere((d) =>
            d['district'] == locationProvider.currentDistrict)['parking_lots'];

    return ListView.builder(
      itemCount: parkingLots.length,
      itemBuilder: (context, index) {
        final lot = parkingLots[index];
        return Card(
          color: Colors.white,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
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
                Text('Type: ${lot['locationType']}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              // Update the selected location in the LocationProvider
              locationProvider.selectLocation({
                'lotID': lot['lotID'],
                'lot_name': lot['lot_name'],
              });

              // Update the last_used_lotID for the user
              final auth = Provider.of<AuthService>(context, listen: false);
              if (auth.user != null) {
                await locationProvider.updateLastUsedLot(auth.user!.userID, lot['lotID']);
              }

              // Navigate back to the MainScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}