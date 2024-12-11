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

  // Default location for fallback
  final LatLng defaultLocation =
      const LatLng(6.467067402188159, 100.5076370309702);

  late Future<Map<String, dynamic>> parkingDataFuture;

  @override
  void initState() {
    super.initState();
    parkingDataFuture = _loadParkingData();
  }

  Future<Map<String, dynamic>> _loadParkingData() async {
    try {
      final parkingSpaces = await ApiService.getParkingData(widget.lotID);
      final locationType = await ApiService.getLocationType(widget.lotID);

      if (locationType.toLowerCase() == 'outdoor') {
        await _loadPolygonsAndMarkers();
      }

      return {
        'parkingSpaces': parkingSpaces,
        'locationType': locationType,
      };
    } catch (e) {
      print('Error loading parking data: $e');
      return {};
    }
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
      CameraUpdate.newLatLngBounds(bounds, 50), // Add padding
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
    final circleCenter = Offset(width / 2, circleRadius);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lotID} Parking'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: parkingDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(
                child:
                    Text('Error: ${snapshot.error ?? "Failed to load data"}'));
          }

          final parkingSpaces =
              snapshot.data!['parkingSpaces'] as List<Map<String, dynamic>>;
          final locationType = snapshot.data!['locationType'];

          return Stack(
            children: [
              if (locationType.toLowerCase() == 'outdoor') ...[
                // Outdoor layout
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialCameraTarget ?? defaultLocation,
                    zoom: 18.0,
                  ),
                  mapType: MapType.satellite,
                  polygons: parkingLotPolygons,
                  markers: parkingMarkers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (pendingBounds != null) {
                      _moveCameraToFitBounds(pendingBounds!);
                      pendingBounds = null; // Clear bounds after moving camera
                    }
                  },
                ),
              ] else ...[
                // Indoor layout
                Padding(
                  padding: const EdgeInsets.only(top: 120.0),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Icon(Icons.arrow_downward, color: Colors.green),
                              Text('Entrance',
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                          Text(
                            'Floor 1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Column(
                            children: [
                              Text('Exit', style: TextStyle(color: Colors.red)),
                              Icon(Icons.arrow_upward, color: Colors.red),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (int i = 0; i < parkingSpaces.length; i += 4)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    for (int j = 0;
                                        j < 4 &&
                                            i + j < parkingSpaces.length;
                                        j++)
                                      ParkingSpace(
                                        space: parkingSpaces[i + j],
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 4,
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
                            _buildLegendItem('Premium', const Color(0xFFFFD54F),
                                Icons.star),
                            _buildLegendItem(
                                'Occupied', Colors.red, Icons.block),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

class ParkingSpace extends StatelessWidget {
  final Map<String, dynamic> space;

  const ParkingSpace({super.key, required this.space});

  @override
  Widget build(BuildContext context) {
    final isAvailable = space['isAvailable'] == true ||
        space['isAvailable'] == 1 ||
        space['isAvailable'] == '1';
    final parkingType = space['parkingType'] ?? 'Regular';
    final parkingSpaceID = space['parkingSpaceID'];

    Color bgColor;
    IconData icon;

    if (!isAvailable) {
      bgColor = Colors.red;
      icon = Icons.block;
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
          bgColor = Colors.grey;
          icon = Icons.local_parking;
      }
    }

    return Container(
      width: 60,
      height: 100,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            parkingSpaceID,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
