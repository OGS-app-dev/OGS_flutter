import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/bus_position.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class TrackBusPage extends StatelessWidget {
  const TrackBusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: const BusPosition(
                      index: 0,
                    ),
                    withNavBar: true,
                    pageTransitionAnimation: PageTransitionAnimation.cupertino,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: pricol, borderRadius: BorderRadius.circular(40)),
                  height: 80,
                  width: 120,
                  child: Center(
                      child: Text(
                    "LH 1",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w400
                    ),
                  )),
                ),
              ),
              GestureDetector(
                onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: const BusPosition(
                      index: 1,
                    ),
                    withNavBar: true,
                    pageTransitionAnimation: PageTransitionAnimation.cupertino,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: pricol, borderRadius: BorderRadius.circular(40)),
                  height: 80,
                  width: 120,
                  child: Center(
                      child: Text(
                    "LH 2",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w400
                    ),
                  )),
                ),
              ),
              GestureDetector(
                onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: const BusPosition(
                      index: 2,
                    ),
                    withNavBar: true,
                    pageTransitionAnimation: PageTransitionAnimation.cupertino,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: pricol, borderRadius: BorderRadius.circular(40)),
                  height: 80,
                  width: 120,
                  child: Center(
                      child: Text(
                    "MBH 1",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w400
                    ),
                  )),
                ),
              ),
              GestureDetector(
                onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: const BusPosition(
                      index: 3,
                    ),
                    withNavBar: true,
                    pageTransitionAnimation: PageTransitionAnimation.cupertino,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: pricol, borderRadius: BorderRadius.circular(40)),
                  height: 80,
                  width: 120,
                  child: Center(
                      child: Text(
                    "MBH 2",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w400
                    ),
                  )),
                ),
              ),
            ],
          ),
        )));
  }
}
