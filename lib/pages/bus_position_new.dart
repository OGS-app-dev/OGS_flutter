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
  final TextEditingController _searchController = TextEditingController();

  List<LatLng> _busLocations = [];
  Timer? _busLocationUpdateTimer;
  LatLng? _userCurrentLocation;
  String _mapType = "street";
  List<String> _searchResults = [];
  Marker? _searchMarker;

  final Map<String, LatLng> _buildingCoordinates = {
    "Main Gate": LatLng(11.3199, 75.9322),
    "Center Circle": LatLng(11.3215522735941, 75.93410745008883),
    "Chemical Gate": LatLng(11.32310277221977, 75.93691330855931),
    "Mega Hostel": LatLng(11.3172114769951, 75.93752554112106),
    "Central Library": LatLng(11.3225, 75.9361),
    "LH": LatLng(11.3220, 75.9370),
    "SOMS": LatLng(11.3218, 75.9380),
    "Auditorium": LatLng(11.3206, 75.9348),
  };

  final LatLng _nitcCenter = const LatLng(11.3215, 75.9360);
  final double _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
   // _fetchBusLocations();
   // _startBusLocationTimer();
  }

  @override
  void dispose() {
    _busLocationUpdateTimer?.cancel();
    _searchController.dispose();
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

  String _getTileUrl() {
    if (_mapType == 'satellite') {
      return 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    } else {
      return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  void _searchBuilding(String query) {
    setState(() {
      _searchResults = _buildingCoordinates.keys
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _focusOnBuilding(String name) {
    final LatLng? coords = _buildingCoordinates[name];
    if (coords != null) {
      _mapController.move(coords, 23.5);
      setState(() {
        _searchController.clear();
        _searchResults.clear();
        _searchMarker = Marker(
          point: coords,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> allMarkers = [];

    // Add bus markers
    // allMarkers.addAll(_busLocations.map((pos) {
    //   return Marker(
    //     width: 50,
    //     height: 50,
    //     point: pos,
    //     child: const Icon(
    //       Icons.directions_bus,
    //       size: 36,
    //       color: Colors.red,
    //     ),
    //   );
    // }));

    // Add search marker if available
    if (_searchMarker != null) {
      allMarkers.add(_searchMarker!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIT Calicut Map'),
        actions: [
          DropdownButton<String>(
            value: _mapType,
            underline: const SizedBox(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _mapType = newValue;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: "street", child: Text("Street")),
              DropdownMenuItem(value: "satellite", child: Text("Satellite")),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _nitcCenter,
              initialZoom: _initialZoom,
              maxZoom: 18,
              minZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(),
                userAgentPackageName: 'com.ogs.busmap',
              ),
              MarkerLayer(markers: allMarkers),
            ],
          ),
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _searchBuilding,
                  decoration: InputDecoration(
                    hintText: 'Search NITC buildings...',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults.clear();
                          _searchMarker = null;
                        });
                      },
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final name = _searchResults[index];
                        return ListTile(
                          title: Text(name),
                          onTap: () => _focusOnBuilding(name),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
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
