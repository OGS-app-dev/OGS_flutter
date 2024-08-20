// ignore_for_file: unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Networking/gps_location.dart';
// import 'package:track_it/widgets/search_bars/search_bar_button.dart';
// import 'package:track_it/widgets/floating_action_buttons/fab_1.dart';
// import 'package:track_it/widgets/floating_action_buttons/fab_2.dart';
// import 'package:track_it/widgets/filter_buttons.dart';
// import 'package:track_it/database/marker_data.dart';
import 'package:provider/provider.dart';
// import 'package:track_it/database/form_response.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../form_response/form_response.dart';
// import '../widgets/fab_1.dart';
// import '../widgets/filter_buttons.dart';
// import '../widgets/loader.dart';

// ignore: must_be_immutable
class GpsScreen extends StatefulWidget {
  static const String id = "GpsScreen";
  GpsLocation? gpsLocation;

  GpsScreen({
    super.key,
    this.gpsLocation,
  });

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> with TickerProviderStateMixin {
  late final SharedPreferences _prefs;
  GoogleMapController? myController;
  final gcontroller = Completer<GoogleMapController>();
  String? userId;
  late GpsLocation gpsLocation;
  Set<Marker> locationCoordinate = {};
  LatLng? _currentCoordinates;
  MapType mapType = MapType.normal;
  int count = 0;
  IconData icon = Icons.search;
  late var markerIcon;
  String searchBar = "Search Here";
  String title = "Search Here";
  Set<Polyline> _polylinesResponse = {};
  bool needGetDirection = true;
  List<Marker> markerList = [];
  Set<Marker> markers = {};
  double newHeading = 0.0;
  bool isPressed = false;
  String distance = "";
  bool firstTime = true;
  int presentLength = 0;
  List<Marker> userMarkerIcon = [const Marker(markerId: MarkerId("value"))];
  final Duration duration = const Duration(milliseconds: 300);
  Set<Marker> setMarker = {};
  int screenNumber = 0;
  Color color = Colors.white60;
  late var responseAns;
  String role = "";
  String email = "";
  String busNo = "";
  String selector = "";
  bool reqFilter = false;
  FormResponse? formResponse;

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void _onMapCreated(controller) {
    myController = controller;
  }

  Marker userMarker(double heading) {
    return Marker(
      markerId: const MarkerId("You"),
      infoWindow: const InfoWindow(title: "You"),
      position: Provider.of<FormResponse>(context, listen: false)
          .currentUserPosition!,
      icon: BitmapDescriptor.fromBytes(
          Provider.of<FormResponse>(context, listen: false).userMapIcon),
      rotation: heading,
      anchor: const Offset(0.5, 0.5),
    );
  }

  Future<void> getLocation() async {
    gpsLocation.getLocation().listen((currentPosition) async {
      //dont need it now since not taking other location
      
      List<LatLng> res =
          await gpsLocation.addFirstLocation(currentPosition, "staff", busNo);
          formResponse?.busLoc.clear();
      print(res);
      formResponse?.busLoc.addAll(res);

      Provider.of<FormResponse>(context, listen: false)
          .addCurrentUserPosition(currentPosition!);
      //dont need it now since not taking all other users location
      if (mounted) {
        setState(() {
          locationCoordinate = gpsLocation.locationCoordinate;
        });
      }
    });
  }

  void initializer() async {
    formResponse = Provider.of<FormResponse>(context, listen: false);
    _prefs = Provider.of<FormResponse>(context, listen: false).prefs!;
    role = Provider.of<FormResponse>(context, listen: false).role;
    email = Provider.of<FormResponse>(context, listen: false).email;
    busNo = Provider.of<FormResponse>(context, listen: false).busNo;
    Future.wait([
      getLocation(),
      rotateUserIcon(),
    ]).then((value) => null);
  }

  Future<void> rotateUserIcon() async {
    FlutterCompass.events?.listen((event) async {
      if (mounted) {
        newHeading = event.heading!;
        _updateUserMarkerRotation(newHeading);
      }
    });
  }

  void _updateUserMarkerRotation(double newHeading) {
    userMarkerIcon[0] = userMarker(newHeading);
    if (context.mounted) {
      setState(() {
        userMarkerIcon;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    gpsLocation = widget.gpsLocation!;
    setState(() {
      _currentCoordinates = LatLng(gpsLocation.currentPosition!.latitude,
          gpsLocation.currentPosition!.longitude);
      // locationCoordinate = gpsLocation.locationCoordinate;
    });
    initializer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Consumer<FormResponse>(
        builder: (context, FormResponse, child) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  flex: 10,
                  child: Stack(
                    children: [
                      GoogleMap(
                        compassEnabled: true,
                        zoomControlsEnabled: false,
                        initialCameraPosition: CameraPosition(
                            target: _currentCoordinates!, zoom: 19),
                        onMapCreated: (controller) => _onMapCreated(controller),
                        markers: role.toLowerCase() == "student"
                            ? (Set.from(locationCoordinate)
                              ..addAll(userMarkerIcon))
                            : userMarkerIcon.toSet(),
                        mapType: mapType,
                        // cameraTargetBounds: CameraTargetBounds(
                        //   LatLngBounds(
                        //       southwest: LatLng(11, 75), northeast: LatLng(11.59, 77)),
                        // ),
                      ),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          // SingleChildScrollView(
                          //   scrollDirection: Axis.horizontal,
                          //   child: Row(
                          //     children: [
                          //       FilterButton(
                          //         title: "Bus No: 1",
                          //         onPressed: () async {
                          //           if(selector == "1"){
                          //             reqFilter = false;
                          //             selector = "";
                          //           }else {
                          //             selector = "1";
                          //             reqFilter = true;
                          //           }
                          //
                          //         },
                          //       ),
                          //       FilterButton(
                          //         title: "Bus No: 2",
                          //         onPressed: () {
                          //           if(selector == "2"){
                          //             reqFilter = false;
                          //             selector = "";
                          //           }else {
                          //             selector = "2";
                          //             reqFilter = true;
                          //           }
                          //         },
                          //       ),
                          //       FilterButton(
                          //         title: "Bus No: 3",
                          //         onPressed: () {
                          //           if(selector == "3"){
                          //             reqFilter = false;
                          //             selector = "";
                          //           }else {
                          //             selector = "3";
                          //             reqFilter = true;
                          //           }
                          //         },
                          //       ),
                          //       FilterButton(
                          //         title: "Bus No: 4",
                          //         onPressed: () {
                          //           if(selector == "4"){
                          //             reqFilter = false;
                          //             selector = "";
                          //           }else {
                          //             selector = "4";
                          //             reqFilter = true;
                          //           }
                          //         },
                          //       ),
                          //       FilterButton(
                          //         title: "Bus No: 5",
                          //         onPressed: () {
                          //           if(selector == "5"){
                          //             reqFilter = false;
                          //             selector = "";
                          //           }else {
                          //             selector = "5";
                          //             reqFilter = true;
                          //           }
                          //         },
                          //       ),
                          //       FilterButton(
                          //         title: "Bus No: 6",
                          //         onPressed: () {
                          //           if(selector == "6"){
                          //             reqFilter = false;
                          //             selector = "";
                          //           }else {
                          //             selector = "6";
                          //             reqFilter = true;
                          //           }
                          //         },
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Expanded(
                            child: SizedBox(),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  children: [
                                    // FAB1(
                                    //   onPressed: () {
                                    //     //to get back to our current location
                                    //     myController?.animateCamera(
                                    //       CameraUpdate.newCameraPosition(
                                    //         CameraPosition(
                                    //             target: FormResponse
                                    //                 .currentUserPosition!,
                                    //             zoom: 19),
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
