import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iprsr/services/api_service.dart';
import 'dart:ui' as ui;

class OutdoorParkingView extends StatefulWidget {
  final List<Map<String, dynamic>> parkingSpaces;
  final String recommendedSpace;
  final String lotID;

  const OutdoorParkingView({
    super.key,
    required this.parkingSpaces,
    required this.recommendedSpace,
    required this.lotID,
  });

  @override
  State<OutdoorParkingView> createState() => _OutdoorParkingViewState();
}

class _OutdoorParkingViewState extends State<OutdoorParkingView> {
  Set<Polygon> parkingLotPolygons = {};
  Set<Marker> parkingMarkers = {};
  LatLng? initialCameraTarget;
  bool isLoading = true;
  late GoogleMapController _mapController;
  LatLngBounds? pendingBounds;

  @override
  void initState() {
    super.initState();
    _loadPolygonsAndMarkers();
  }

  @override
  void didUpdateWidget(OutdoorParkingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parkingSpaces != oldWidget.parkingSpaces ||
        widget.recommendedSpace != oldWidget.recommendedSpace ||
        widget.lotID != oldWidget.lotID) {
      _loadMarkers();
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
      initialCameraTarget = const LatLng(6.467067402188159, 100.5076370309702);
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

    for (var space in widget.parkingSpaces) {
      try {
        if (space['coordinates'] != null) {
          List<String> coords = space['coordinates'].split(',');
          if (coords.length == 2) {
            final lat = double.tryParse(coords[0].trim());
            final lng = double.tryParse(coords[1].trim());
            if (lat == null || lng == null) {
              continue;
            }

            bool isAvailable = space['isAvailable'] == true ||
                space['isAvailable'] == 1 ||
                space['isAvailable'] == '1';

            String parkingType = space['parkingType'] ?? 'Regular';
            String spaceId = space['parkingSpaceID'];
            bool isRecommended = spaceId == widget.recommendedSpace;

            Color markerColor = isRecommended
                ? Colors.green
                : _getMarkerColor(isAvailable, parkingType);

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
    final circleCenter = const Offset(width / 2, circleRadius);
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
    return isLoading || initialCameraTarget == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialCameraTarget!,
              zoom: 18.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (pendingBounds != null) {
                _moveCameraToFitBounds(pendingBounds!);
                pendingBounds = null;
              }
            },
            mapType: MapType.satellite,
            markers: parkingMarkers,
            polygons: parkingLotPolygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          );
  }
}