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
  final String busId; 
  const BusPosition({super.key, required this.busId});

  @override
  State<BusPosition> createState() => _BusPositionState();
}

class _BusPositionState extends State<BusPosition> {
  String prevLocName = "";
  String currLocName = "";
  Timer? _timer;

  double stepheight = 60; // Compact height to fit all stops on page
  int buspos = -1;
  bool towardsMBH = true;

  bool get isMBHBus => widget.busId.contains("mbh");

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
        // MBH route logic: CHEM_GATE -> ARCHITECTURE -> AUDITORIUM -> CCD -> CENTER_CIRCLE -> MAIN_GATE -> MBH
        if (isMBHBus) {
          if (currLocName == "CHEM_GATE") {
            buspos = 0;
          } else if (currLocName == "ARCHITECTURE") {
            buspos = 1;
          } else if (currLocName == "AUDITORIUM") {
            buspos = 2;
          } else if (currLocName == "CCD") {
            buspos = 3;
          } else if (currLocName == "CENTER_CIRCLE") {
            buspos = 4;
          } else if (currLocName == "MAIN_GATE") {
            buspos = 5;
          } else if (currLocName == "MEGA_HOSTEL") { // MBH
            buspos = 6;
          } else if (currLocName == "NOT_A_PLACE") {
            // Handle intermediate positions based on previous location
            if (prevLocName == "CHEM_GATE") {
              buspos = 1; // Between CHEM_GATE and ARCHITECTURE
            } else if (prevLocName == "ARCHITECTURE") {
              buspos = 2; // Between ARCHITECTURE and AUDITORIUM
            } else if (prevLocName == "AUDITORIUM") {
              buspos = 3; // Between AUDITORIUM and CCD
            } else if (prevLocName == "CCD") {
              buspos = 4; // Between CCD and CENTER_CIRCLE
            } else if (prevLocName == "CENTER_CIRCLE") {
              buspos = 5; // Between CENTER_CIRCLE and MAIN_GATE
            } else if (prevLocName == "MAIN_GATE") {
              buspos = 6; // Between MAIN_GATE and MBH
            } else {
              buspos = -1;
            }
          } else {
            buspos = -1;
          }
        } else {
          // LH route logic: CHEM_GATE -> ARCHITECTURE -> AUDITORIUM -> CCD -> CENTER_CIRCLE -> MAIN_GATE -> LH -> SOMS
          if (currLocName == "CHEM_GATE") {
            buspos = 0;
          } else if (currLocName == "ARCHITECTURE") {
            buspos = 1;
          } else if (currLocName == "AUDITORIUM") {
            buspos = 2;
          } else if (currLocName == "CCD") {
            buspos = 3;
          } else if (currLocName == "CENTER_CIRCLE") {
            buspos = 4;
          } else if (currLocName == "MAIN_GATE") {
            buspos = 5;
          } else if (currLocName == "LH_STOP") { // LH
            buspos = 6;
          } else if (currLocName == "SOMS") {
            buspos = 7;
          } else if (currLocName == "NOT_A_PLACE") {
            // Handle intermediate positions based on previous location
            if (prevLocName == "CHEM_GATE") {
              buspos = 1; // Between CHEM_GATE and ARCHITECTURE
            } else if (prevLocName == "ARCHITECTURE") {
              buspos = 2; // Between ARCHITECTURE and AUDITORIUM
            } else if (prevLocName == "AUDITORIUM") {
              buspos = 3; // Between AUDITORIUM and CCD
            } else if (prevLocName == "CCD") {
              buspos = 4; // Between CCD and CENTER_CIRCLE
            } else if (prevLocName == "CENTER_CIRCLE") {
              buspos = 5; // Between CENTER_CIRCLE and MAIN_GATE
            } else if (prevLocName == "MAIN_GATE") {
              buspos = 6; // Between MAIN_GATE and LH
            } else if (prevLocName == "LH_STOP") {
              buspos = 7; // Between LH and SOMS
            } else {
              buspos = -1;
            }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              buspos == -1
                  ? const SpinKitThreeBounce(size: 25, color: pricol)
                  : _buildBusTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusTimeline() {
    List<String> mbhStops = [
      "Chemical Gate",
      "Architecture Building",
      "Auditorium",
      "CCD",
      "Center Circle",
      "Main Gate",
      "MBH"
    ];

    List<String> wbhStops = [
      "Chemical Gate",
      "Architecture Building", 
      "Auditorium",
      "CCD",
      "Center Circle",
      "Main Gate",
      "LH Stop",
      "SOMS"
    ];

    List<String> stops = isMBHBus ? mbhStops : wbhStops;
    double containerHeight = stops.length * stepheight;

    return Container(
      height: containerHeight + 40,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            top: stepheight * buspos,
            child: Container(
              height: stepheight - 5,
              width: MediaQuery.of(context).size.width,
              color: yel.withOpacity(0.3),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              Stack(
                children: [
                  Container(
                    width: 50, 
                    height: containerHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(stops.length, (_) {
                        return Container(
                          width: 6, 
                          height: 25,
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
                    left: 5, 
                    right: 5, 
                    top: stepheight * buspos + 20, 
                    child: Container(
                      padding: const EdgeInsets.all(6), 
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(LineIcons.bus, size: 28), 
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20), 
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: stops.asMap().entries.map((entry) {
                    return Container(
                      height: stepheight,
                      alignment: Alignment.centerLeft, 
                      child: Text(
                        entry.value,
                        style: GoogleFonts.outfit(
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          color: buspos == entry.key ? pricol : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 20), 
            ],
          ),
        ],
      ),
    );
  }
}