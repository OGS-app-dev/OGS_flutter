import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class CollegeMapScreen extends StatefulWidget {
  const CollegeMapScreen({super.key});

  @override
  State<CollegeMapScreen> createState() => _CollegeMapScreenState();
}

class _CollegeMapScreenState extends State<CollegeMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _userCurrentLocation;
  String _mapType = "street";
  List<String> _searchResults = [];
  Marker? _searchMarker;

  final LatLng _nitcCenter = const LatLng(11.3215, 75.9360);
  final double _initialZoom = 16.0;

  final Map<String, LatLng> _buildingCoordinates = {
    "Main Gate": LatLng(11.3199, 75.9322),
    "Center Circle": LatLng(11.321552, 75.934107),
    "Chemical Gate": LatLng(11.323103, 75.936913),
    "Mega Hostel": LatLng(11.317211, 75.937526),
    "Central Library": LatLng(11.3225, 75.9361),
    "Lecture Hall Complex (LH)": LatLng(11.3220, 75.9370),
    "School of Management Studies (SOMS)": LatLng(11.3218, 75.9380),
    "Auditorium": LatLng(11.3206, 75.9348),
    "CSED": LatLng(11.32295, 75.93460),
    "EEE Dept": LatLng(11.3223, 75.9350),
    "Mechanical Workshop": LatLng(11.3210, 75.9358),
    "Hostel D": LatLng(11.3189, 75.9354),
    "Guest House": LatLng(11.3194, 75.9316),
    "Admin Block": LatLng(11.3213, 75.9337),
    "Architecture Dept": LatLng(11.3226, 75.9368),
    "IC Engines Lab": LatLng(11.3204, 75.9356),
    "Training & Placement": LatLng(11.3209, 75.9340),
    "Physics Dept": LatLng(11.3222, 75.9364),
  };

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userCurrentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  String _getTileUrl() {
    return _mapType == 'satellite'
        ? 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  void _searchBuilding(String query) {
    setState(() {
      _searchResults = _buildingCoordinates.keys
          .where((name) =>
              name.toLowerCase().contains(query.trim().toLowerCase()))
          .toList();
    });
  }

  void _focusOnBuilding(String name) {
    final LatLng? coords = _buildingCoordinates[name];
    if (coords != null) {
      _mapController.move(coords, 19.5);
      setState(() {
        _searchController.clear();
        _searchResults.clear();
        _searchMarker = Marker(
          point: coords,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 50),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> allMarkers = [];

    // Add searched location
    if (_searchMarker != null) {
      allMarkers.add(_searchMarker!);
    }

    // Add user location
    if (_userCurrentLocation != null) {
      allMarkers.add(
        Marker(
          width: 60,
          height: 60,
          point: _userCurrentLocation!,
          child: Column(
            children: const [
              Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40),
              Text("You", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
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
              maxZoom: 22,
              minZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(),
                userAgentPackageName: 'com.ogs.nitcmap',
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
          _mapController.move(
            _userCurrentLocation ?? _nitcCenter,
            _initialZoom,
          );
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
