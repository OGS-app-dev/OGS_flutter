// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:line_icons/line_icons.dart';

import 'package:ogs/constants/coordinates.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:provider/provider.dart';

class BusPosition extends StatefulWidget {
  const BusPosition({super.key});

  @override
  State<BusPosition> createState() => _BusPositionState();
}

class _BusPositionState extends State<BusPosition> {
  String prevLocName = "";
  String currLocName = "";
  LatLng prevLoc = LatLng(0, 0);
  Timer? _timer;

  FormResponse? formResponse;

  double stepheight = 130;
  int buspos = -1;
  bool towardsMBH = true;

  void startTimer() {
    _timer = Timer?.periodic(const Duration(seconds: 5), (timer) {
      getNewLoc();
      setState(() {
        currLocName;
        prevLocName;
      });
    });
  }

  void getNewLoc() {
    String newLocName = getNextIdx(formResponse!.currentUserPosition!, true);

    if (currLocName != newLocName) {
      prevLocName = currLocName;
      currLocName = newLocName;

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
        body: SafeArea(
            child: Center(
          child: buspos == -1
              ? const Text("Wait while tracking the bus")
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(
                      width: 40,
                    ),
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: MediaQuery.of(context).size.height * .7,
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 8,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              Container(
                                width: 8,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              Container(
                                width: 8,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              Container(
                                width: 8,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                              Container(
                                width: 8,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                            ],
                          ),
                        ),
                        AnimatedPositioned(
                          duration: Duration(seconds: 1),
                          curve: Curves.easeIn,
                          left: 10,
                          right: 10,
                          top: stepheight * buspos + 20,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                buspos = (buspos + 1) % 5;
                              });
                            },
                            child: Container(
                              //width: 60,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(50)),
                              child: const Icon(
                                LineIcons.bus,
                                size: 35,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "Main Building",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1,),
                        Text(
                          "Chemical Gate",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                          
                        ),
                        const SizedBox(height: 1,),

                        Text(
                          "Mega Hostel",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                          
                        ),
                      ],
                    )),
                    const SizedBox(
                      width: 40,
                    ),
                  ],
                ),
        )));
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
