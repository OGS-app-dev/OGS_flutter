import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ogs/Networking/gps_location.dart';
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
  LatLng prevLoc = LatLng(0,0);
  Timer? _timer;

  FormResponse? formResponse;

  void startTimer() {
    _timer = Timer?.periodic(const Duration(seconds: 5), (timer) {
      getNewLoc();
      setState(() {
        currLocName;
        prevLocName;
      });
    });
  }

  void getNewLoc(){

    String newLocName =  getNextIdx(formResponse!.currentUserPosition!,true);
    if(currLocName != newLocName){
      prevLocName = currLocName;
      currLocName = newLocName;
    }


  }
  @override
  void initState() {
    formResponse = Provider.of<FormResponse>(context,listen:false);
    startTimer();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text("Coming from: $prevLocName",style: const TextStyle(fontSize: 20),),
          Text("Current position: $currLocName",style: const TextStyle(fontSize: 20),),
        ],
      ),
    );
  }
}
