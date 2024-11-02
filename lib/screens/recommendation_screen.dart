import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:iprsr/services/auth_service.dart';
import 'package:iprsr/models/user.dart';
import 'package:iprsr/providers/countdown_provider.dart';

class RecommendationScreen extends StatefulWidget {
  final User user;
  final String location;

  const RecommendationScreen({
    required this.user,
    required this.location,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late Future<Map<String, dynamic>> recommendationsFuture;

  @override
  void initState() {
    super.initState();
    recommendationsFuture = fetchRecommendationsAndSpaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Parking Recommendations for ${widget.location}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                        Icons.accessible, "Special", Colors.blueAccent),
                    SizedBox(width: 8),
                    _buildLegendItem(Icons.female, "Female", Colors.pinkAccent),
                    SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.family_restroom, "Family", Colors.purpleAccent),
                    SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.electric_car, "EV Car", Colors.tealAccent),
                    SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.star, "Premium", const Color(0xFFFFD54F)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Icons.local_parking, "Regular",
                        const Color.fromRGBO(158, 158, 158, 1)),
                    SizedBox(width: 8),
                    _buildLegendItem(
                        Icons.thumb_up, "Recommended", Colors.greenAccent),
                    SizedBox(width: 8),
                    _buildLegendItem(Icons.block, "Occupied", Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green),
                    Text('Entrance', style: TextStyle(color: Colors.green)),
                  ],
                ),
                Column(
                  children: [
                    Text('Exit', style: TextStyle(color: Colors.red)),
                    Icon(Icons.arrow_upward, color: Colors.red),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: recommendationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(
                      child: Text('No parking spaces available.'));
                } else {
                  final parkingSpaces = snapshot.data!['parkingSpaces']
                      as List<Map<String, dynamic>>;
                  final String recommendedSpace =
                      snapshot.data!['recommendedSpace'] as String;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        for (int i = 0; i < parkingSpaces.length; i += 4)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (int j = 0;
                                  j < 4 && i + j < parkingSpaces.length;
                                  j++)
                                ParkingSpace(
                                  space: parkingSpaces[i + j],
                                  isRecommended: parkingSpaces[i + j]
                                          ['parkingSpaceID'] ==
                                      recommendedSpace,
                                  onShowPaymentDialog: () {
                                    _showPaymentDialog(
                                        context,
                                        parkingSpaces[i + j]['parkingSpaceID']);
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openGoogleMaps(widget.location);
        },
        child: Icon(Icons.navigation, color: Colors.white),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendationsAndSpaces() async {
    try {
      final parkingSpaces = await ApiService.getParkingSpaces(widget.location);
      final recommendedSpace =
          await ApiService.getRecommendations(widget.user.userID, widget.location);
      return {
        'parkingSpaces': parkingSpaces,
        'recommendedSpace': recommendedSpace,
      };
    } catch (e) {
      throw Exception('Failed to fetch data: $e');
    }
  }

  void openGoogleMaps(String locationName) async {
    final Map<String, String> locationLinks = {
      'SoC': 'https://maps.app.goo.gl/fp4eZGT4dvbbiTzj7',
      'C-mart Changlun': 'https://maps.app.goo.gl/h7v6aZmaSJdRRMoQA',
      'Aman Central': 'https://maps.app.goo.gl/AH3AXEUqXGrWbME67',
      'V Mall': 'https://maps.app.goo.gl/d5CZPygW47Ftthwd8',
    };

    final url = locationLinks[locationName];
    if (url != null) {
      final Uri uri = Uri.parse(url);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print('Could not launch $url');
        }
      } catch (e) {
        print("Error launching URL: $e");
      }
    } else {
      print('No URL found for location: $locationName');
    }
  }

  void _showPaymentDialog(BuildContext context, String parkingSpaceID) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Premium Parking"),
        content: Text(
            "This is a premium parking spot for $parkingSpaceID. Proceed with payment?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              bool success = await ApiService.lockParkingSpace(parkingSpaceID, duration: 5);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Parking spot $parkingSpaceID locked for 5 minutes.'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Start the countdown with the current user's userID
                Provider.of<CountdownProvider>(context, listen: false)
                    .startCountdown(5, parkingSpaceID, widget.user.userID);

                setState(() {
                  recommendationsFuture = fetchRecommendationsAndSpaces();
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to lock the parking spot."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Pay"),
          ),
        ],
      );
    },
  );
}




  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
      ],
    );
  }
}

class ParkingSpace extends StatelessWidget {
  final Map<String, dynamic> space;
  final bool isRecommended;
  final VoidCallback onShowPaymentDialog;

  const ParkingSpace({
    required this.space,
    required this.isRecommended,
    required this.onShowPaymentDialog,
  });

  @override
  Widget build(BuildContext context) {
    final countdownProvider = Provider.of<CountdownProvider>(context);
    final authProvider = Provider.of<AuthService>(context, listen: false);
    final bool isAvailable = space['isAvailable'].toString() == '1';
    final String parkingType = space['parkingType']?.toString() ?? 'Regular';
    final String parkingSpaceID = space['parkingSpaceID'];

    // Determine if this is the premium parking space with an active countdown for this user
    bool isPremiumAndCountingDown = countdownProvider.isCountingDown &&
        countdownProvider.activeParkingSpaceID == parkingSpaceID &&
        countdownProvider.activeUserID == authProvider.user?.userID; // Check userID

    Color bgColor;
    IconData? icon;
    double iconSize = 24;

    if (isPremiumAndCountingDown) {
      bgColor = Colors.orangeAccent; // Color for premium with countdown
      icon = Icons.timer;
      iconSize = 28;
    } else if (!isAvailable) {
      bgColor = const Color.fromARGB(255, 255, 117, 117); // Occupied for others
      icon = Icons.block;
      iconSize = 28;
    } else if (isRecommended) {
      bgColor = Colors.greenAccent;
      icon = Icons.thumb_up;
    } else {
      switch (parkingType) {
        case 'Special':
          bgColor = const Color(0xFF90CAF9);
          icon = Icons.accessible;
          break;
        case 'Female':
          bgColor = const Color(0xFFF48FB1);
          icon = Icons.female;
          break;
        case 'Family':
          bgColor = const Color(0xFFCE93D8);
          icon = Icons.family_restroom;
          break;
        case 'EV Car':
          bgColor = const Color(0xFFA5D6A7);
          icon = Icons.electric_car;
          break;
        case 'Premium':
          bgColor = const Color(0xFFFFD54F);
          icon = Icons.star;
          break;
        default:
          bgColor = Colors.grey[500]!;
          icon = Icons.local_parking;
      }
    }

    return GestureDetector(
      onTap: onShowPaymentDialog,
      child: Container(
        width: 60,
        height: 100,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isRecommended ? Colors.green : Colors.black12,
            width: isRecommended ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
            if (isPremiumAndCountingDown)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${countdownProvider.remainingTime.inMinutes}:${(countdownProvider.remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else if (isAvailable || isRecommended)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  parkingSpaceID,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
