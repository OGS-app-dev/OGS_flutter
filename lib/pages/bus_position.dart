import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';

import 'package:ogs/constants.dart';
import 'package:ogs/constants/coordinates.dart';

class BusPosition extends StatefulWidget {
  final String busId; // e.g., "lh_1", "mbh_2"
  const BusPosition({super.key, required this.busId});

  @override
  State<BusPosition> createState() => _BusPositionState();
}

class _BusPositionState extends State<BusPosition> {
  String prevLocName = "";
  String currLocName = "";
  Timer? _timer;

  double stepheight = 112;
  int buspos = -1;
  bool towardsMBH = true;

  bool get isMBHBus => widget.busId.startsWith("mbh");

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final newPos = await _fetchBusLocation();
      if (newPos != null) {
        _updateBusPosition(newPos);
      }
    });
  }

  Future<LatLng?> _fetchBusLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("Location")
          .doc(widget.busId)
          .get();

      final geo = doc.data()?['location'];
      if (geo is GeoPoint) {
        return LatLng(geo.latitude, geo.longitude);
      }
    } catch (e) {
      debugPrint("Error fetching location for ${widget.busId}: $e");
    }
    return null;
  }

  void _updateBusPosition(LatLng newPos) {
    String newLocName = getNextIdx(newPos, isMBHBus);
    if (currLocName != newLocName) {
      prevLocName = currLocName;
      currLocName = newLocName;

      setState(() {
        // MBH route logic
        if (isMBHBus) {
          if (currLocName == "CENTER_CIRCLE") {
            towardsMBH = true;
            buspos = 0;
          } else if (currLocName == "MEGA_HOSTEL") {
            towardsMBH = false;
            buspos = 4;
          } else if (currLocName == "CHEM_GATE" || currLocName == "MAIN_GATE") {
            buspos = 2;
          } else if (currLocName == "NOT_A_PLACE") {
            if (prevLocName == "MEGA_HOSTEL") {
              buspos = 3;
            } else if (prevLocName == "CENTER_CIRCLE") {
              buspos = 1;
            } else {
              buspos = towardsMBH ? 3 : 1;
            }
          } else {
            buspos = -1;
          }
        } else {
          // LH route logic
          if (currLocName == "CENTER_CIRCLE") {
            buspos = 1;
          } else if (currLocName == "LH_STOP") {
            buspos = 3;
          } else if (currLocName == "SOMS") {
            towardsMBH = false;
            buspos = 4;
          } else if (currLocName == "CHEM_GATE") {
            towardsMBH = true;
            buspos = 0;
          } else if (currLocName == "MAIN_GATE") {
            buspos = 2;
          } else {
            buspos = -1;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: buspos == -1
              ? const SpinKitThreeBounce(size: 25, color: pricol)
              : _buildBusTimeline(),
        ),
      ),
    );
  }

  Widget _buildBusTimeline() {
    List<String> mbhStops = [
      "Center Circle",
      "Auditorium",
      "Chemical Gate",
      "Kattangal",
      "Mega Hostel",
    ];

    List<String> lhStops = [
      "Chemical Gate",
      "Center Circle",
      "Main Gate",
      "LH Stop",
      "SOMS",
    ];

    List<String> stops = isMBHBus ? mbhStops : lhStops;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(seconds: 1),
          curve: Curves.easeIn,
          top: stepheight * buspos,
          child: Container(
            height: 105,
            width: MediaQuery.of(context).size.width,
            color: yel,
          ),
        ),
        SizedBox(
          height: 550,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 40),
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 550,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (_) {
                        return Container(
                          width: 8,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      }),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeIn,
                    left: 10,
                    right: 10,
                    top: stepheight * buspos + 30,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(LineIcons.bus, size: 35),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SizedBox(
                  height: 550,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: stops
                        .asMap()
                        .entries
                        .map((entry) => Text(
                              entry.value,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color:
                                    buspos == entry.key ? pricol : Colors.black,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ],
    );
  }
}
