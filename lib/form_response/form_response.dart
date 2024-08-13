import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Networking/gps_location.dart';


class FormResponse extends ChangeNotifier {
  SharedPreferences? prefs;
  var markerIconSmall;
  var markerIconBig;
  String searchBarTitle = "Search Here";
  String role = "";
  String email = "";
  String userName = "";
  IconData icon = Icons.search;
  List<Marker> _markers = [];
  List<Marker> _orginalSetMarker = [];
  List<Marker> markerState = [];
  String searchItem = "";
  Set<Polyline> polylineSet = {};
  LatLng? currentUserPosition;
  LatLng? destination;
  bool needGetDirection = false;
  var userMapIcon;
  var heading;
  String busNo = "";
  bool showDistance = false;
  late GpsLocation gpsLocation;

  PersistentTabController? tabController = PersistentTabController();
  



  get markers {
    return _markers.toSet();
  }

  get originalMarker {
    return _orginalSetMarker;
  }

  get presentlength {
    return markerState.length;
  }

  Future<void> initializeSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  void changeShowDistance(bool value) {
    showDistance = value;
    notifyListeners();
  }

  void addCurrentUserPosition(Position postion) {
    currentUserPosition = LatLng(postion.latitude, postion.longitude);
    notifyListeners();
  }


  //changes the search


 void setEmail(String email){
    this.email = email;
 }

  Future<void> getIcon() async {
    markerIconSmall =
        await getBytesFromAsset('lib/assets/icons/bitmap icon.png', 80);
    markerIconBig =
        await getBytesFromAsset('lib/assets/icons/bitmap icon.png', 100);
    userMapIcon = await getBytesFromAsset('lib/assets/icons/userIcon.png', 80);
  }

  //to convert an image to bitmapDiscripto icon(bytedata)
  Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  void createOriginalSet() {
    _orginalSetMarker = List.from(_markers);
  }

  void goBack() {
    _markers = List.from(_orginalSetMarker);
  }

  void addSharedPref(SharedPreferences pref){
    prefs = pref;
    notifyListeners();
  }

  //gets back the original set of markers
  // void createMarkers() {
  //   if (_markers.isEmpty) {
  //     for (int i = 0; i < markerData.markerId.length; i++) {
  //       _markers.add(
  //         Marker(
  //           markerId: MarkerId(markerData.markerId[i]),
  //           infoWindow: InfoWindow(title: markerData.markerTitle[i]),
  //           position: markerData.markerPosition[i],
  //           icon: BitmapDescriptor.fromBytes(markerIconSmall),
  //         ),
  //       );
  //     }
  //   }
  //   markerState = List.from(_markers);
  // }
}
