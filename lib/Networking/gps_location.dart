import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GpsLocation {
  final _auth = FirebaseAuth.instance;
  final _cloud = FirebaseFirestore.instance;
  User? _currentUser;
  late LocationPermission permission;
  Position? currentPosition;
  List<double> geoLocationLatitude = [];
  List<double> geoLocationLongitude = [];
  List<LatLng> busLocs = [const LatLng(1, 1)];
  Set<Marker> locationCoordinate = {};
  List<String> userId = [];
  dynamic longitude;
  dynamic latitude;
  StreamController<Position?> controller = StreamController<Position?>();

  static double getDist(LatLng dist1, LatLng dist2) {
    return Geolocator.distanceBetween(
        dist1.latitude, dist1.longitude, dist2.latitude, dist2.longitude);
  }

  Future<void> requestPermission() async {
    permission = await Geolocator.requestPermission();
  }

  get currentUserId {
    return _currentUser?.displayName;
  }

  Future<void> locate() async {
    currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
  }

  Future<int> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        _currentUser = user;
      }
      print(user);
    } catch (e) {
      print(e.toString());
    }
    return 0;
  }

  Future<void> getFirstLocation() async {
    await requestPermission();
    currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    // await addFirstLocation(currentPosition);
  }

  Stream<Position?> getLocation() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      yield currentPosition;
    }
  }

  Future<List<LatLng>> addFirstLocation(
      Position? currentPosition, String role, String userDisplayName) async {
    if (role.toLowerCase() == "staff") {
      try {
        await _cloud.collection("Location").doc(userDisplayName).set({
          "latitude": currentPosition?.latitude,
          "longitude": currentPosition?.longitude,
        });
      } catch (e) {
        print(e.toString());
        await _cloud.collection("Location").doc(userDisplayName).update({
          "latitude": currentPosition?.latitude,
          "longitude": currentPosition?.longitude,
        });
      }
    }
    await locator();
    return busLocs;
  }

  void coordinates() {
    locationCoordinate.clear();
    for (var i = 0; i < geoLocationLongitude.length; i++) {
      locationCoordinate.add(
        Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(
            userId[i] == currentUserId
                ? BitmapDescriptor.hueBlue
                : BitmapDescriptor.hueRed,
          ),
          markerId: MarkerId(userId[i]),
          infoWindow:
              InfoWindow(title: userId[i] == currentUserId ? "You" : userId[i]),
          position: LatLng(geoLocationLatitude[i], geoLocationLongitude[i]),
        ),
      );
    }
  }

  Future<void> locator() async {
    await _cloud.collection("Location").orderBy(FieldPath.documentId,descending: false).get().then((value) {
      geoLocationLongitude.clear();
      geoLocationLatitude.clear();
      locationCoordinate.clear();
      busLocs.clear();
      userId.clear();
      for (var data in value.docs) {
        userId.add(data.id.toString());
        geoLocationLatitude
            .add(double.parse(data.data()["latitude"].toString()));
        geoLocationLongitude
            .add(double.parse(data.data()["longitude"].toString()));
        busLocs.add(LatLng(double.parse(data.data()["latitude"].toString()),
            double.parse(data.data()["longitude"].toString())));
      }
      print("-------------------------------");
      print(busLocs);
      // coordinates();
    }, onError: (e) => print(e));
  }
}
