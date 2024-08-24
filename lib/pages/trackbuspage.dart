import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/bus_position.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class TrackBusPage extends StatelessWidget {
  const TrackBusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
          GestureDetector(
            onTap: () {
              PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: const BusPosition(index: 1,),
                withNavBar: true,
                pageTransitionAnimation: PageTransitionAnimation.cupertino,
              );
            },
            child: Container(
              color: pricol,
              height: 50,
              width: 200,
              child: Text("lh2"),
            ),
          )
        ],),
      ))
    );
  }
}
