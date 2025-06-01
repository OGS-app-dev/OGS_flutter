import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // For user's current location
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching bus locations
import 'dart:async'; // For timers

// Assuming you have your coordinate constants defined
import 'package:ogs/constants/coordinates.dart';
import 'package:ogs/Networking/gps_location.dart'; // For getDist

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

  // Initial map center and zoom level for NIT Calicut
  final LatLng _nitcCenter = const LatLng(11.3215, 75.9360); // Approximate center of NITC
  final double _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _fetchBusLocations();
    _startBusLocationTimer();
    _getCurrentUserLocation();
  }

  @override
  void dispose() {
    _busLocationUpdateTimer?.cancel();
    super.dispose();
  }

  // Function to fetch bus locations from Firestore
  Future<void> _fetchBusLocations() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("Location")
          .orderBy(FieldPath.documentId, descending: false)
          .get();

      setState(() {
        _busLocations = querySnapshot.docs.map((doc) {
          return LatLng(
            double.parse(doc.data()["latitude"].toString()),
            double.parse(doc.data()["longitude"].toString()),
          );
        }).toList();
      });
    } catch (e) {
      print("Error fetching bus locations: $e");
    }
  }

  // Timer to periodically update bus locations
  void _startBusLocationTimer() {
    _busLocationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchBusLocations();
    });
  }

  // Function to get the current user's location
  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, handle appropriately
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle appropriately
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _userCurrentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    // You can define routes here or fetch them from a file/database
    // For demonstration, let's define a simple polyline for a bus route
    final List<LatLng> busRoutePolyline = [
      const LatLng(11.3199, 75.9322), // MAIN_GATE
      const LatLng(11.3215522735941, 75.93410745008883), // CENTER_CIRCLE
      const LatLng(11.32310277221977, 75.93691330855931), // CHEM_GATE
      const LatLng(11.3172114769951, 75.93752554112106), // MEGA_HOSTEL
    ];


    // Create markers for bus locations
    List<Marker> busMarkers = _busLocations.asMap().entries.map((entry) {
      int index = entry.key;
      LatLng busPosition = entry.value;
      return Marker(
        width: 80.0,
        height: 80.0,
        point: busPosition,
        child: const Icon(
          Icons.bus_alert, // Or LineIcons.bus if you have line_icons
          color: Colors.red,
          size: 40,
        ),
        // You might want to add info windows for bus numbers
        // anchorPos: AnchorPos.align(AnchorAlign.top),
      );
    }).toList();

    // Add user location marker
    if (_userCurrentLocation != null) {
      busMarkers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: _userCurrentLocation!,
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 40,
          ),
          // You might want to add info windows for user
          // anchorPos: AnchorPos.align(AnchorAlign.top),
        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('NIT Calicut Map & Bus Tracking'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _nitcCenter,
          initialZoom: _initialZoom,
          maxZoom: 18.0, // Prevent zooming in too much
          minZoom: 13.0, // Prevent zooming out too much
          keepAlive: true, // Keep the map state alive
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.yourcompany.yourappname', // Replace with your package name
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: busRoutePolyline,
                color: Colors.blue,
                strokeWidth: 5.0,
              ),
              // You can add more polylines for different bus routes
            ],
          ),
          MarkerLayer(
            markers: busMarkers,
          ),
          // You can add more layers here, like CircleLayer for geofencing
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Re-center map on NITC
          _mapController.move(_nitcCenter, _initialZoom);
        },
        child: const Icon(Icons.location_searching),
      ),
    );
  }
}