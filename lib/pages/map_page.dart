import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/dbservices.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/pages/notificationpage.dart';

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
  // Gates & Entry
  "Main Gate": LatLng(11.31990, 75.93220), // verified
  "Chemical Gate": LatLng(11.32310, 75.93691),
  "Back Gate": LatLng(11.31800, 75.93900), // approximate

  // Central
  "Center Circle": LatLng(11.32155, 75.93411),
  "Rajpath": LatLng(11.32160, 75.93450), // main walkway

  // Academic Buildings & Departments
  "Central Library": LatLng(11.32250, 75.93610),
  "Admin Block": LatLng(11.32130, 75.93370),
  "Auditorium": LatLng(11.32060, 75.93480),
  "Lecture Hall Complex (LHC)": LatLng(11.32200, 75.93700),
  "School of Management Studies (SOMS)": LatLng(11.32180, 75.93800),
  "Computer Science & Engineering (CSED)": LatLng(11.32295, 75.93460),
  "Electrical Engineering (EEE Dept)": LatLng(11.32230, 75.93500),
  "Electronics & Communication (ECE)": LatLng(11.32270, 75.93480),
  "Mechanical Engineering Dept": LatLng(11.32100, 75.93580),
  "Civil Engineering Dept": LatLng(11.32220, 75.93600),
  "Physics Dept": LatLng(11.32220, 75.93640),
  "Architecture & Planning Dept": LatLng(11.32260, 75.93680),
  "Chemical Engineering Dept": LatLng(11.32380, 75.93710),
  "Chemistry Dept": LatLng(11.32240, 75.93620),
  "Bioscience & Engineering": LatLng(11.32300, 75.93590),
  "Mathematics Dept": LatLng(11.32210, 75.93630),
  "Material Science & Engineering": LatLng(11.32310, 75.93600),

  // Labs & Facilities
  "Mechanical Workshop": LatLng(11.32100, 75.93580),
  "IC Engines Lab": LatLng(11.32040, 75.93560),
  "Central Computer Centre": LatLng(11.32240, 75.93470),

  // Canteens & Coop Stores
  "Main Canteen": LatLng(11.31950, 75.93160),
  "Mini Canteen": LatLng(11.31900, 75.93200),
  "Co-operative Store": LatLng(11.32280, 75.93450),

  // Hostels
  "Hostel A": LatLng(11.31880, 75.93400),
  "Hostel B": LatLng(11.31860, 75.93350),
  "Hostel C": LatLng(11.31850, 75.93450),
  "Hostel D": LatLng(11.31890, 75.93540),
  "Hostel E": LatLng(11.31920, 75.93560),
  "Hostel F": LatLng(11.31940, 75.93600),
  "Hostel G": LatLng(11.31960, 75.93580),
  "Mega Hostel": LatLng(11.31721, 75.93753),
  "Girls Hostels (LH Blocks)": LatLng(11.32210, 75.93670),

  // Residential & Guest
  "Guest House": LatLng(11.31940, 75.93160),
  "Professor Apartments": LatLng(11.31800, 75.93700),

  // Training & Placement / CDE
  "Training & Placement": LatLng(11.32090, 75.93400),
  "Career Development Centre": LatLng(11.32090, 75.93400),

  // Sports & Recreation
  "Sports Complex": LatLng(11.32000, 75.93350),
  "Open Air Theatre": LatLng(11.32120, 75.93420),
  "Swimming Pool": LatLng(11.32050, 75.93320),
  "Gymnasium / Health Centre": LatLng(11.32060, 75.93300),

  // Others
  "Institute Guest House": LatLng(11.31940, 75.93160),
  "Day Care Centre": LatLng(11.32250, 75.93350),
};


  final _fireDb = FireDb();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _getUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == 'street' ? 'satellite' : 'street';
    });
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

  String getFirstName(
      DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();
    if (userData != null && userData['name'] != null) {
      return userData['name'].split(" ")[0];
    } else if (user?.displayName != null) {
      return user!.displayName!.split(" ")[0];
    } else if (user?.email != null) {
      return user!.email!.split("@")[0];
    } else {
      return "User";
    }
  }

  Widget getProfileImage(
      DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();
    if (userData != null && userData['profileImage'] != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(userData['profileImage']),
        backgroundColor: pricol,
      );
    } else if (user?.photoURL != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(user!.photoURL!),
        backgroundColor: pricol,
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: pricol,
        ),
        child: const Icon(CupertinoIcons.person_fill, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> allMarkers = [];

    if (_searchMarker != null) {
      allMarkers.add(_searchMarker!);
    }

    if (_userCurrentLocation != null) {
      allMarkers.add(
        Marker(
          width: 60,
          height: 60,
          point: _userCurrentLocation!,
          child: const Column(
            children: [
              Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40),
              Text("You", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            FutureBuilder(
              future: _fireDb.getUserDetails(currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: pricol,
                    ),
                    child: const Icon(CupertinoIcons.person_fill,
                        color: Colors.white),
                  );
                }
                var docSnapshot = snapshot.data;
                return getProfileImage(docSnapshot, currentUser);
              },
            ),
            const SizedBox(width: 10),
            Flexible(
              child: FutureBuilder(
                future: _fireDb.getUserDetails(currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SpinKitThreeBounce(
                      size: 10,
                      color: pricol,
                    );
                  }
                  var docSnapshot = snapshot.data;
                  String firstName = getFirstName(docSnapshot, currentUser);
                  return Text(
                    "Hello, $firstName!",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color:pricol,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campus Tracking',
              style: GoogleFonts.outfit(
                color:pricol,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 8,
                          offset: Offset(1, 8),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchBuilding,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        hintText: "Search Departments,Lecture Halls etc..",
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(CupertinoIcons.search, color: yel),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                              _searchMarker = null;
                            });
                          },
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _toggleMapType,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: yel,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FFCC00),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.satellite, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          _mapType == 'street' ? 'Satellite' : 'Street',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
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
              ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
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
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 70), // Adjust height based on your nav bar
  child: FloatingActionButton(
    onPressed: () {
      _mapController.move(_userCurrentLocation ?? _nitcCenter, _initialZoom);
    },
    child: const Icon(Icons.my_location),
  ),
),

    );
  }
}
