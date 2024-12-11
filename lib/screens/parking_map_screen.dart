import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iprsr/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ParkingMapScreen extends StatefulWidget {
  final String lotID;

  const ParkingMapScreen({super.key, required this.lotID});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  late GoogleMapController mapController;
  Set<Polygon> parkingLotPolygons = {};
  Set<Marker> parkingSpaceMarkers = {};
  Map<String, LatLng> locationCoordinates = {};
  bool isLoading = true;

  // Add layer visibility controls
  bool showParkingLots = true;
  bool showParkingSpaces = true;

//default location
  final LatLng defaultLocation = const LatLng(6.467067402188159, 100.5076370309702);

  
  @override
  //initialize state
  void initState() {
    super.initState();
    _loadCoordinates();
    _checkLocationPermission();
  }

  //check location permission
  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  //load coordinates
  Future<void> _loadCoordinates() async {
    try {
      print('Starting to load coordinates...');
      final coords = await ApiService.getParkingLotCoordinates();
      print('Received coordinates: $coords');
      
      if (mounted) {
        setState(() {
          locationCoordinates = coords;
          isLoading = false;
        });
        
        // Only create polygons and markers if we have the specific location
        if (locationCoordinates.containsKey(widget.lotID)) {
          print('Creating polygon for location: ${widget.lotID}');
          _createParkingLotPolygon();
          _createParkingSpaceMarkers();
        } else {
          print('Location not found in coordinates: ${widget.lotID}');
        }
      }
    } catch (e, stackTrace) {
      print('Error loading coordinates: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //create parking lot polygon
  void _createParkingLotPolygon() async {
    try {
      // Get the lotID from the location name
      String lotID = ApiService.locationMapping[widget.lotID] ?? widget.lotID;
      List<LatLng> boundaryPoints = await ApiService.getParkingLotBoundary(lotID);
      
      if (boundaryPoints.isNotEmpty) {
        setState(() {
          parkingLotPolygons.add(
            Polygon(
              polygonId: const PolygonId('parkingLot'),
              points: boundaryPoints,
              strokeWidth: 2,
              strokeColor: Colors.blue,
              fillColor: Colors.blue.withOpacity(0.3),
            ),
          );
        });
      } else {
        print('No boundary points found for lotID: $lotID');
      }
    } catch (e) {
      print('Error creating parking lot polygon: $e');
    }
  }

  //create custom marker icon
  Future<BitmapDescriptor> _createCustomMarkerIcon(Color color, String text, String parkingType) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 60.0;
    final width = 40.0;  // Rectangle width
    final height = 60.0; // Rectangle height
    final cornerRadius = 8.0;
    
    // Create the background with rounded corners
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size - width) / 2,
        (size - height) / 2,
        width,
        height
      ),
      Radius.circular(cornerRadius)
    );
    canvas.drawRRect(rect, paint);
    
    // Draw the parking type icon
    IconData iconData = _getParkingTypeIcon(parkingType);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: iconData.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - height) / 2 + 8, // Position icon at top
      ),
    );
    
    // Draw the space ID
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size + height) / 2 - 24, // Position text at bottom
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(uint8List);
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
      case 'Regular':
        return Icons.local_parking;
      default:
        return Icons.local_parking;
    }
  }

  void _createParkingSpaceMarkers() async {
  try {
    final parkingSpaces = await ApiService.getParkingData(widget.lotID);
    
    Set<Marker> newMarkers = {};
    
    // Process all spaces in parallel
    await Future.wait(parkingSpaces.map((space) async {
      if (space['coordinates'] != null) {
        List<String> coords = space['coordinates'].split(',');
        if (coords.length == 2) {
          double lat = double.parse(coords[0].trim());
          double lng = double.parse(coords[1].trim());
          
          bool isAvailable = space['isAvailable'] == 1 || space['isAvailable'] == '1';
          String parkingType = space['parkingType'] ?? 'Regular';
          String spaceId = space['parkingSpaceID'];
          
          Color markerColor = _getMarkerColor(isAvailable, parkingType);
          BitmapDescriptor markerIcon = await _createCustomMarkerIcon(markerColor, spaceId, parkingType);

          newMarkers.add(
            Marker(
              markerId: MarkerId(spaceId),
              position: LatLng(lat, lng),
              icon: markerIcon,
              infoWindow: InfoWindow(
                title: 'Space $spaceId',
                snippet: '$parkingType${isAvailable ? " - Available" : " - Occupied"}',
              ),
            ),
          );
        }
      }
    }));
    
    if (mounted) {
      setState(() {
        parkingSpaceMarkers = newMarkers;
      });
    }
    } catch (e) {
    print('Error creating parking space markers: $e');
  }
}

  // Helper method to determine marker color
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
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lotID} Parking'),
        actions: [
          // Add layer controls in the app bar
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers),
            onSelected: (String value) {
              setState(() {
                switch (value) {
                  case 'lots':
                    showParkingLots = !showParkingLots;
                    break;
                  case 'spaces':
                    showParkingSpaces = !showParkingSpaces;
                    break;
                }
              });
            },
            itemBuilder: (BuildContext context) => [
              CheckedPopupMenuItem(
                checked: showParkingLots,
                value: 'lots',
                child: const Text('Parking Lots'),
              ),
              CheckedPopupMenuItem(
                checked: showParkingSpaces,
                value: 'spaces',
                child: const Text('Parking Spaces'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Existing Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: locationCoordinates[widget.lotID] ?? defaultLocation,
              zoom: 19.0,
            ),
            mapType: MapType.satellite,
            polygons: showParkingLots ? parkingLotPolygons : {},
            markers: showParkingSpaces ? parkingSpaceMarkers : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),
          
          // Legend Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(8),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // First Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('Regular', Colors.grey, Icons.local_parking),
                        _buildLegendItem('Special', const Color(0xFF90CAF9), Icons.accessible),
                        _buildLegendItem('Female', const Color(0xFFF48FB1), Icons.female),
                        _buildLegendItem('Family', const Color(0xFFCE93D8), Icons.family_restroom),
                      ],
                    ),
                    const SizedBox(height: 8), // Space between rows
                    // Second Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem('EV Car', const Color(0xFFA5D6A7), Icons.electric_car),
                        _buildLegendItem('Premium', const Color(0xFFFFD54F), Icons.star),
                        _buildLegendItem('Occupied', Colors.red, Icons.block),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
} 