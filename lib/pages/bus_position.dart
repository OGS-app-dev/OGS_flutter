// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';

import 'package:ogs/constants/coordinates.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:provider/provider.dart';

class BusPosition extends StatefulWidget {
  final int index;
  const BusPosition({super.key, required this.index});

  @override
  State<BusPosition> createState() => _BusPositionState();
}

class _BusPositionState extends State<BusPosition> {
  String prevLocName = "";
  String currLocName = "";
  LatLng prevLoc = const LatLng(0, 0);
  Timer? _timer;

  FormResponse? formResponse;

  double stepheight = 112;
  int buspos = -1;
  bool towardsMBH = true;

  Map<int, bool> busmap = {0: false, 1: false, 2: true, 3: true};

  void startTimer() {
    _timer = Timer?.periodic(const Duration(seconds: 5), (timer) {
      getNewLoc(formResponse!.newBusLoc[widget.index]);
      //  print("buslochihi----------------${widget.index}");
      //  print(formResponse?.busLoc);
      if (mounted) {
        setState(() {
          currLocName;
          prevLocName;
        });
      }
    });
  }

  void getNewLoc(LatLng newPos) {
    String newLocName = getNextIdx(newPos, busmap[widget.index]!);
    if (currLocName != newLocName) {
      prevLocName = currLocName;
      currLocName = newLocName;
      if (busmap[widget.index] == true) {
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
          } else if (prevLocName == "CHEM_GATE" || prevLocName == "MAIN_GATE") {
            if (towardsMBH) {
              buspos = 3;
            } else {
              buspos = 1;
            }
          }
        } else {
          buspos = -1;
        }
      } else {
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
        }
      }
    }
  }

  @override
  void initState() {
    formResponse = Provider.of<FormResponse>(context, listen: false);

    startTimer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: busmap[widget.index] == true
          ? SafeArea(
              child: Center(
                child: buspos == -1
                    ? const SpinKitThreeBounce(
                        size: 25,
                        color: pricol,
                      )
                    : Stack(
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
                                const SizedBox(
                                  width: 40,
                                ),
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 550,
                                      decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedPositioned(
                                      duration: const Duration(seconds: 1),
                                      curve: Curves.easeIn,
                                      left: 10,
                                      right: 10,
                                      top: stepheight * buspos + 30,
                                      child: Container(
                                        //width: 60,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(50)),
                                        child: const Icon(
                                          LineIcons.bus,
                                          size: 35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                    child: SizedBox(
                                  height: 550,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        "Center Circle",
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: buspos == 0 ? pricol : pricol,
                                        ),
                                      ),
                                      Text(
                                        widget.index == 3
                                            ? "- - - - - - - -"
                                            : "Auditorium",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 1 ? pricol : pricol),
                                      ),
                                      Text(
                                        widget.index == 3
                                            ? "Main Gate"
                                            : "Chemical Gate",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 2 ? pricol : pricol),
                                      ),
                                      Text(
                                        widget.index == 3
                                            ? "- - - - - - - -"
                                            : "Kattangal",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 3 ? pricol : pricol),
                                      ),
                                      Text(
                                        "Mega Hostel",
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: buspos == 4 ? pricol : pricol,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(
                                  width: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : SafeArea(
              child: Center(
                child: buspos == -1
                    ? const SpinKitThreeBounce(
                        size: 25,
                        color: pricol,
                      )
                    : Stack(
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
                                const SizedBox(
                                  width: 40,
                                ),
                                Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 550,
                                      decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          Container(
                                            width: 8,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedPositioned(
                                      duration: const Duration(seconds: 1),
                                      curve: Curves.easeIn,
                                      left: 10,
                                      right: 10,
                                      top: stepheight * buspos + 30,
                                      child: Container(
                                        //width: 60,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(50)),
                                        child: const Icon(
                                          LineIcons.bus,
                                          size: 35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                    child: SizedBox(
                                  height: 550,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                        "Chemical Gate",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 0 ? pricol : pricol),
                                      ),
                                      Text(
                                        "Center Circle",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 1 ? pricol : pricol),
                                      ),
                                      Text(
                                        "Main Gate",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 2 ? pricol : pricol),
                                      ),
                                      Text(
                                        "LH Stop",
                                        style: GoogleFonts.outfit(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                buspos == 3 ? pricol : pricol),
                                      ),
                                      Text(
                                        "SOMS",
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: buspos == 4 ? pricol : pricol,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(
                                  width: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}



/*Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "Coming from: $prevLocName",
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            "Current position: $currLocName",
            style: const TextStyle(fontSize: 20),
          ),
        ],
      ),
    );*/
