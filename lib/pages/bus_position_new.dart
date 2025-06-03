import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeMapScreen extends StatefulWidget {
  const CollegeMapScreen({super.key});

  @override
  State<CollegeMapScreen> createState() => _CollegeMapScreenState();
}

class _CollegeMapScreenState extends State<CollegeMapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _busLocations = [];
  Timer? _busLocationUpdateTimer;
  LatLng? _userCurrentLocation;

  final LatLng _nitcCenter = const LatLng(11.3215, 75.9360);
  final double _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _fetchBusLocations();
    _startBusLocationTimer();
    // _getCurrentUserLocation();
  }

  @override
  void dispose() {
    _busLocationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBusLocations() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("Location")
        .orderBy(FieldPath.documentId)
        .get();

    setState(() {
      _busLocations = querySnapshot.docs.map((doc) {
        final data = doc.data();
        final GeoPoint geoPoint = data["location"];
        return LatLng(geoPoint.latitude, geoPoint.longitude);
      }).toList();
    });
  } catch (e) {
    debugPrint("Error fetching bus locations: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch bus locations")),
      );
    }
  }
}


  void _startBusLocationTimer() {
    _busLocationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchBusLocations(),
    );
  }

  Future<void> _getCurrentUserLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userCurrentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> busRoutePolyline = [
      const LatLng(11.3199, 75.9322),
      const LatLng(11.3215522735941, 75.93410745008883),
      const LatLng(11.32310277221977, 75.93691330855931),
      const LatLng(11.3172114769951, 75.93752554112106),
    ];

    List<Marker> busMarkers = _busLocations.map((busPosition) {
      return Marker(
        width: 50,
        height: 50,
        point: busPosition,
        child: const Icon(
          Icons.directions_bus,
          size: 36,
          color: Colors.red,
        ),
      );
    }).toList();

    // if (_userCurrentLocation != null) {
    //   busMarkers.add(
    //     Marker(
    //       width: 60,
    //       height: 60,
    //       point: _userCurrentLocation!,
    //       child: const Icon(
    //         Icons.person_pin_circle,
    //         size: 40,
    //         color: Colors.blue,
    //       ),
    //     ),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIT Calicut Map'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _nitcCenter,
          initialZoom: _initialZoom,
          maxZoom: 18,
          minZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ogs.busmap',
          ),
          // PolylineLayer(
          //   polylines: [
          //     Polyline(
          //       points: busRoutePolyline,
          //       color: Colors.orange.withOpacity(0.85),
          //       strokeWidth: 5.0,
          //     ),
          //   ],
          // ),
          // MarkerLayer(markers: busMarkers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_nitcCenter, _initialZoom);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
