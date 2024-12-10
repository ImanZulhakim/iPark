import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iprsr/services/api_service.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class OutdoorParkingView extends StatefulWidget {
  final List<Map<String, dynamic>> parkingSpaces;
  final String recommendedSpace;
  final String location;

  const OutdoorParkingView({
    super.key,
    required this.parkingSpaces,
    required this.recommendedSpace,
    required this.location,
  });

  @override
  State<OutdoorParkingView> createState() => _OutdoorParkingViewState();
}

class _OutdoorParkingViewState extends State<OutdoorParkingView> {
  Set<Polygon> parkingLotPolygons = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolygons();
  }

  Future<void> _loadPolygons() async {
    try {
      final coords = await ApiService.getParkingLotCoordinates();
      if (mounted) {
        setState(() {
          // Create polygon for the current location
          if (coords.containsKey(widget.location)) {
            parkingLotPolygons.add(
              Polygon(
                polygonId: PolygonId(widget.location),
                points: [
                  coords[widget.location]!,
                  LatLng(coords[widget.location]!.latitude + 0.0003, coords[widget.location]!.longitude + 0.0005),
                  LatLng(coords[widget.location]!.latitude + 0.0003, coords[widget.location]!.longitude - 0.0005),
                  LatLng(coords[widget.location]!.latitude - 0.0003, coords[widget.location]!.longitude - 0.0005),
                  LatLng(coords[widget.location]!.latitude - 0.0003, coords[widget.location]!.longitude + 0.0005),
                ],
                fillColor: Colors.blue.withOpacity(0.3),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            );
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading polygons: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _getLocationCoordinates(widget.location),
        zoom: 19.0,
      ),
      mapType: MapType.satellite,
      markers: _createMarkers(),
      polygons: parkingLotPolygons,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

 Set<Marker> _createMarkers() {
  Set<Marker> markers = {};
  
  for (var space in widget.parkingSpaces) {
    if (space['coordinates'] != null) {
      List<String> coords = space['coordinates'].split(',');
      if (coords.length == 2) {
        double lat = double.parse(coords[0].trim());
        double lng = double.parse(coords[1].trim());
        
        bool isAvailable = space['isAvailable'] == 1 || space['isAvailable'] == '1';
        String parkingType = space['parkingType'] ?? 'Regular';
        String spaceId = space['parkingSpaceID'];
        bool isRecommended = spaceId == widget.recommendedSpace;
        
        Color markerColor = isRecommended 
            ? Colors.green
            : _getMarkerColor(isAvailable, parkingType);

        _createCustomMarkerIcon(markerColor, spaceId, parkingType).then((markerIcon) {
          markers.add(
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
        });
      }
    }
  }
  return markers;
}

  Color _getMarkerColor(bool isAvailable, String parkingType) {
    if (!isAvailable) return Colors.red;
    
    switch (parkingType) {
      case 'Special': return const Color(0xFF90CAF9);
      case 'Female': return const Color(0xFFF48FB1);
      case 'Family': return const Color(0xFFCE93D8);
      case 'EV Car': return const Color(0xFFA5D6A7);
      case 'Premium': return const Color(0xFFFFD54F);
      default: return Colors.grey;
    }
  }

  LatLng _getLocationCoordinates(String location) {
    // Add default coordinates for each location
    final Map<String, LatLng> coordinates = {
      'SoC': const LatLng(6.467067402188159, 100.5076370309702),
      'DMAS': const LatLng(6.467144415889556, 100.50597248173986),
      'DTSO': const LatLng(6.465756607732289, 100.50398509459093),
      'VMALL': const LatLng(6.462567082976349, 100.50071606950915),
    };
    
    return coordinates[location] ?? const LatLng(6.467067402188159, 100.5076370309702);
  }



}


  // Add after the existing _getMarkerColor method

  Future<BitmapDescriptor> _createCustomMarkerIcon(Color color, String text, String parkingType) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 60.0;
    final width = 40.0;
    final height = 60.0;
    final cornerRadius = 8.0;

    // Create the rectangle path
    final path = Path()
      ..moveTo(size / 2 - width / 2 + cornerRadius, 0)
      ..lineTo(size / 2 + width / 2 - cornerRadius, 0)
      ..arcToPoint(
        Offset(size / 2 + width / 2, cornerRadius),
        radius: Radius.circular(cornerRadius),
      )
      ..lineTo(size / 2 + width / 2, height - cornerRadius)
      ..arcToPoint(
        Offset(size / 2 + width / 2 - cornerRadius, height),
        radius: Radius.circular(cornerRadius),
      )
      ..lineTo(size / 2 - width / 2 + cornerRadius, height)
      ..arcToPoint(
        Offset(size / 2 - width / 2, height - cornerRadius),
        radius: Radius.circular(cornerRadius),
      )
      ..lineTo(size / 2 - width / 2, cornerRadius)
      ..arcToPoint(
        Offset(size / 2 - width / 2 + cornerRadius, 0),
        radius: Radius.circular(cornerRadius),
      );

    // Draw the rectangle
    canvas.drawPath(
      path,
      Paint()..color = color,
    );

    // Add the parking type icon
    final IconData icon = _getParkingTypeIcon(parkingType);
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center),
    )..pushStyle(ui.TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontFamily: icon.fontFamily,
      ))
      ..addText(String.fromCharCode(icon.codePoint));
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(
      paragraph,
      Offset((size - paragraph.width) / 2, 8),
    );

    // Add the text
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
        (size + height) / 2 - 24,
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