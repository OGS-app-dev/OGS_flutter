
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ogs/Networking/gps_location.dart';


const List<LatLng> coordinatesBoys = [

  LatLng(11.319994770730467,  75.93264721346195), // MAIN_GATE
  LatLng(11.3215522735941,  75.93410745008883), // CENTER_CIRCLE
  LatLng(11.32310277221977,  75.93691330855931), // CHEM_GATE
  LatLng(11.3172114769951,  75.93752554112106), // MEGA_HOSTEL

];

const List<LatLng> coordinatesGirls = [

  LatLng(11.319994770730467,  75.93264721346195), // MAIN_GATE
  LatLng(11.32310277221977,  75.93691330855931), // CHEM_GATE
  LatLng(11.3215522735941,  75.93410745008883), // CENTER_CIRCLE
  LatLng(11.31484967744654,  75.932466895059), // SOMS
  LatLng(11.318211816487084,  75.93108353184496), // LH_STOP

];

// const String MAIN_GATE =

const List<String> coordinateNameBoys = [
  MAIN_GATE,CENTER_CIRCLE,CHEM_GATE,MEGA_HOSTEL
];

const List<String> coordinateNameGirls = [
  MAIN_GATE,CENTER_CIRCLE,CHEM_GATE,CENTER_CIRCLE,SOMS,LH_STOP
];

const String CHEM_GATE = "CHEM_GATE",MAIN_GATE = "MAIN_GATE",MEGA_HOSTEL = "MEGA_HOSTEL",CENTER_CIRCLE="CENTER_CIRCLE",SOMS="SOMS",LH_STOP="LH_STOP";


String getNextIdx(LatLng currLoc,bool type){
  if(type) {
    for (int i = 0; i<coordinatesBoys.length;i++){
      if(GpsLocation.getDist(currLoc,coordinatesBoys[i]) <= 100){
        return coordinateNameBoys[i];
      }
    }
  }else{
    for (int i = 0; i<coordinatesGirls.length;i++){
      if(GpsLocation.getDist(currLoc,coordinatesGirls[i]) <= 100){
        return coordinateNameGirls[i];
      }
    }
  }
  return "NOT_A_PLACE";
}