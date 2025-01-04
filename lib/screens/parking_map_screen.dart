import 'dart:async'; // For StreamController and Timer
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iprsr/services/api_service.dart';
import 'dart:ui' as ui;

class ParkingMapScreen extends StatefulWidget {
  final String lotID;

  const ParkingMapScreen({super.key, required this.lotID});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  late GoogleMapController _mapController;
  Set<Polygon> parkingLotPolygons = {};
  Set<Marker> parkingMarkers = {};
  LatLng? initialCameraTarget;
  bool isLoading = true;
  LatLngBounds? pendingBounds;
  String? _lotName;
  String? _currentFloor;
  List<String> _floors = [];
  Map<String, List<Map<String, dynamic>>> spacesByFloor = {};
  String? _locationType; // Added to store location type

  // StreamController for parking spaces
  final StreamController<List<Map<String, dynamic>>> _parkingSpaceController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Timer for auto-refresh
  Timer? _refreshTimer;

  // Default location for fallback
  final LatLng defaultLocation =
      const LatLng(6.467067402188159, 100.5076370309702);

  @override
  void initState() {
    super.initState();
    if (widget.lotID == 'DefaultLotID') {
      // Handle the case where no lot is selected
      isLoading = false;
    } else {
      _fetchLotName(); // Fetch the lot name when the screen initializes
      _loadParkingData(); // Load initial parking data
      _startRefreshTimer(); // Start the auto-refresh timer
    }
  }

  // Start the auto-refresh timer
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadParkingData(); // Refresh parking data every 5 seconds
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel the timer
    _parkingSpaceController.close(); // Close the stream controller
    super.dispose();
  }

  // Fetch the lot name using the API service
  Future<void> _fetchLotName() async {
    try {
      final lotName = await ApiService.getLotName(widget.lotID);
      if (mounted) {
        setState(() {
          _lotName = lotName; // Update the state with the fetched lot name
        });
      }
    } catch (e) {
      print('Error fetching lot name: $e');
      if (mounted) {
        setState(() {
          _lotName = 'Unknown Lot';
        });
      }
    }
  }

  Future<void> _loadParkingData() async {
    try {
      final parkingSpaces = await ApiService.getParkingData(widget.lotID);
      final locationType = await ApiService.getLocationType(widget.lotID);

      setState(() {
        _locationType = locationType; // Update location type
      });

      if (locationType.toLowerCase() == 'outdoor') {
        await _loadPolygonsAndMarkers();
      } else {
        _organizeSpacesByFloor(parkingSpaces); // Organize spaces by floor
      }

      // Emit updated parking spaces to the stream
      _parkingSpaceController.add(parkingSpaces);
    } catch (e) {
      print('Error loading parking data: $e');
    }
  }

  void _organizeSpacesByFloor(List<Map<String, dynamic>> parkingSpaces) {
    spacesByFloor = {};
    Set<String> floors = {};

    for (var space in parkingSpaces) {
      String? floorName =
          space['coordinates']?.toString().toLowerCase().split('|').first;
      if (floorName == null ||
          !(floorName.startsWith('floor') || floorName.startsWith('level'))) {
        floorName = 'Unknown';
      }
      if (!spacesByFloor.containsKey(floorName)) {
        spacesByFloor[floorName] = [];
        floors.add(floorName);
      }
      spacesByFloor[floorName]!.add(space);
    }

    List<String> sortedFloors = floors.toList()
      ..sort((a, b) {
        int aNum = int.tryParse(a.split(' ').last) ?? 0;
        int bNum = int.tryParse(b.split(' ').last) ?? 0;
        return aNum.compareTo(bNum);
      });

    setState(() {
      _floors = sortedFloors;
      _currentFloor = _floors.isNotEmpty ? _floors.first : 'No Floors';
    });
  }

  void _navigateFloor(String direction) {
    if (_floors.isEmpty || _currentFloor == null) return;

    final currentIndex = _floors.indexOf(_currentFloor!);
    if (currentIndex == -1) return;

    setState(() {
      if (direction == 'up' && currentIndex < _floors.length - 1) {
        _currentFloor = _floors[currentIndex + 1];
      } else if (direction == 'down' && currentIndex > 0) {
        _currentFloor = _floors[currentIndex - 1];
      }
    });
  }

  Future<void> _loadPolygonsAndMarkers() async {
    try {
      final List<LatLng> boundaryPoints =
          await ApiService.getParkingLotBoundary(widget.lotID);

      if (boundaryPoints.isNotEmpty) {
        setState(() {
          parkingLotPolygons.add(
            Polygon(
              polygonId: PolygonId(widget.lotID),
              points: boundaryPoints,
              fillColor: Colors.blue.withOpacity(0.3),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          );
        });

        final bounds = _calculateLatLngBounds(boundaryPoints);
        pendingBounds = bounds;
      } else {
        print('No boundary points found for lotID: ${widget.lotID}');
      }

      await _loadMarkers();
      _setInitialCameraTarget();
    } catch (e) {
      print('Error loading polygons or markers: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setInitialCameraTarget() {
    if (parkingLotPolygons.isNotEmpty) {
      final boundaryPoints = parkingLotPolygons.first.points;
      double latSum = 0, lngSum = 0;
      for (var point in boundaryPoints) {
        latSum += point.latitude;
        lngSum += point.longitude;
      }
      initialCameraTarget = LatLng(
        latSum / boundaryPoints.length,
        lngSum / boundaryPoints.length,
      );
    } else {
      initialCameraTarget = defaultLocation;
    }
  }

  LatLngBounds _calculateLatLngBounds(List<LatLng> points) {
    double? minLat, minLng, maxLat, maxLng;

    for (var point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Future<void> _moveCameraToFitBounds(LatLngBounds bounds) async {
    await _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Future<void> _loadMarkers() async {
    Set<Marker> markers = {};
    final parkingSpaces = await ApiService.getParkingData(widget.lotID);

    for (var space in parkingSpaces) {
      try {
        if (space['coordinates'] != null) {
          List<String> coords = space['coordinates'].split(',');
          if (coords.length == 2) {
            final lat = double.tryParse(coords[0].trim());
            final lng = double.tryParse(coords[1].trim());
            if (lat == null || lng == null) continue;

            bool isAvailable = space['isAvailable'] == true ||
                space['isAvailable'] == 1 ||
                space['isAvailable'] == '1';

            String parkingType = space['parkingType'] ?? 'Regular';
            String spaceId = space['parkingSpaceID'];

            Color markerColor = _getMarkerColor(isAvailable, parkingType);

            final markerIcon =
                await _createCustomMarkerIcon(markerColor, parkingType);

            markers.add(
              Marker(
                markerId: MarkerId(spaceId),
                position: LatLng(lat, lng),
                icon: markerIcon,
                infoWindow: InfoWindow(
                  title: 'Space $spaceId',
                  snippet:
                      '$parkingType${isAvailable ? " - Available" : " - Occupied"}',
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error processing parking space: $e');
      }
    }

    setState(() {
      parkingMarkers = markers;
    });
  }

  Color _getMarkerColor(bool isAvailable, String parkingType) {
    if (!isAvailable) return Colors.red;

    switch (parkingType) {
      case 'Special':
        return const Color(0xFF90CAF9);
      case 'Female':
        return const Color(0xFFF48FB1);
      case 'Family':
        return const Color(0xFFCE93D8);
      case 'EV Car':
        return const Color(0xFFA5D6A7);
      case 'Premium':
        return const Color(0xFFFFD54F);
      default:
        return Colors.grey;
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(
      Color color, String parkingType) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const width = 60.0;
    const height = 100.0;

    final paint = Paint()..color = color;

    const circleRadius = width / 2;
    const circleCenter = Offset(width / 2, circleRadius);
    canvas.drawCircle(circleCenter, circleRadius, paint);

    final path = Path()
      ..moveTo(width / 2, height)
      ..lineTo(0, circleRadius)
      ..lineTo(width, circleRadius)
      ..close();
    canvas.drawPath(path, paint);

    final cutoutPaint = Paint()..color = Colors.white;
    const cutoutRadius = width / 4;
    canvas.drawCircle(circleCenter, cutoutRadius, cutoutPaint);

    final icon = _getParkingTypeIcon(parkingType);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: icon.fontFamily,
          color: Colors.black,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        circleCenter.dx - textPainter.width / 2,
        circleCenter.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  IconData _getParkingTypeIcon(String parkingType) {
    switch (parkingType) {
      case 'Special':
        return Icons.accessible;
      case 'Female':
        return Icons.female;
      case 'Family':
        return Icons.family_restroom;
      case 'EV Car':
        return Icons.electric_car;
      case 'Premium':
        return Icons.star;
      default:
        return Icons.local_parking;
    }
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black26),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lotName != null ? '$_lotName Parking' : 'Loading...'),
      ),
      body: widget.lotID == 'DefaultLotID'
          ? const Center(
              child: Text(
                'No parking lot selected. Please select a parking lot from the main screen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            )
          : Column(
              children: [
                // Legend
                Container(
                  alignment: Alignment.topLeft,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                  'Regular', Colors.grey, Icons.local_parking),
                              _buildLegendItem('Special', const Color(0xFF90CAF9),
                                  Icons.accessible),
                              _buildLegendItem('Female', const Color(0xFFF48FB1),
                                  Icons.female),
                              _buildLegendItem('Family', const Color(0xFFCE93D8),
                                  Icons.family_restroom),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem('EV Car', const Color(0xFFA5D6A7),
                                  Icons.electric_car),
                              _buildLegendItem(
                                  'Premium', const Color(0xFFFFD54F), Icons.star),
                              _buildLegendItem(
                                  'Occupied', Colors.red, Icons.block),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Conditional rendering based on location type
                if (_locationType?.toLowerCase() == 'indoor')
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _parkingSpaceController.stream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return Center(
                              child: Text(
                                  'Error: ${snapshot.error ?? "Failed to load data"}'));
                        }

                        final currentFloorSpaces = _currentFloor != null &&
                                spacesByFloor.containsKey(_currentFloor)
                            ? List<Map<String, dynamic>>.from(
                                spacesByFloor[_currentFloor] ?? [])
                            : <Map<String, dynamic>>[];

                        if (currentFloorSpaces.isEmpty) {
                          return const Center(
                            child: Text(
                                'No parking spaces available on this floor.'),
                          );
                        }

                        // Group current floor spaces into wings (10 spaces per wing)
                        final List<List<Map<String, dynamic>>> wings = [];
                        for (var i = 0; i < currentFloorSpaces.length; i += 10) {
                          wings.add(currentFloorSpaces.sublist(
                            i,
                            i + 10 > currentFloorSpaces.length
                                ? currentFloorSpaces.length
                                : i + 10,
                          ));
                        }

                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7, // Fixed height
                          child: InteractiveViewer(
                            boundaryMargin:
                                const EdgeInsets.all(double.infinity),
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Center(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        width: wings.length * 320.0,
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            const Positioned(
                                              top: 0,
                                              left: 0,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.arrow_downward,
                                                      color: Color.fromARGB(
                                                          255, 67, 230, 62)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'ENTRANCE',
                                                    style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 67, 230, 62),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'EXIT',
                                                    style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 209, 45, 45),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_downward,
                                                      color: Color.fromARGB(
                                                          255, 209, 45, 45)),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 32.0, bottom: 32.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: List.generate(
                                                    wings.length, (index) {
                                                  return ParkingWing(
                                                    title:
                                                        'Wing ${String.fromCharCode(65 + index)}',
                                                    spaces: wings[index],
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else if (_locationType?.toLowerCase() == 'outdoor')
                  Expanded(
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (pendingBounds != null) {
                          _moveCameraToFitBounds(pendingBounds!);
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: initialCameraTarget ?? defaultLocation,
                        zoom: 15,
                      ),
                      polygons: parkingLotPolygons,
                      markers: parkingMarkers,
                      mapType: MapType.satellite, // Set to satellite view
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}

class ParkingWing extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> spaces;

  const ParkingWing({
    super.key,
    required this.title,
    required this.spaces,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  (spaces.length / 2).ceil(),
                  (index) => RotatedBox(
                    quarterTurns: 1,
                    child: ParkingSpace(
                      space: spaces[index],
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                color: Colors.white,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  (spaces.length / 2).floor(),
                  (index) => RotatedBox(
                    quarterTurns: 1,
                    child: ParkingSpace(
                      space: spaces[index + (spaces.length / 2).ceil()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ParkingSpace extends StatelessWidget {
  final Map<String, dynamic> space;

  const ParkingSpace({
    super.key,
    required this.space,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = space['isAvailable'] == true ||
        space['isAvailable'] == 1 ||
        space['isAvailable'] == '1';
    final String parkingType = space['parkingType']?.toString() ?? 'Regular';
    final String parkingSpaceID = space['parkingSpaceID'];

    Color bgColor = _getMarkerColor(isAvailable, parkingType);
    IconData icon = _getParkingTypeIcon(isAvailable, parkingType);

    return Container(
      width: 60,
      height: 100,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black12,
          width: 1,
        ),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
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

  Color _getMarkerColor(bool isAvailable, String parkingType) {
    if (!isAvailable) return Colors.red;

    switch (parkingType) {
      case 'Special':
        return const Color(0xFF90CAF9);
      case 'Female':
        return const Color(0xFFF48FB1);
      case 'Family':
        return const Color(0xFFCE93D8);
      case 'EV Car':
        return const Color(0xFFA5D6A7);
      case 'Premium':
        return const Color(0xFFFFD54F);
      default:
        return Colors.grey;
    }
  }

  IconData _getParkingTypeIcon(bool isAvailable, String parkingType) {
    if (!isAvailable) {
      return Icons.block; // No entry icon for occupied spaces
    }

    switch (parkingType) {
      case 'Special':
        return Icons.accessible;
      case 'Female':
        return Icons.female;
      case 'Family':
        return Icons.family_restroom;
      case 'EV Car':
        return Icons.electric_car;
      case 'Premium':
        return Icons.star;
      default:
        return Icons.local_parking;
    }
  }
}