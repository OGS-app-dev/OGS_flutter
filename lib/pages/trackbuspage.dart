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
              _buildBusButton(context, "LH 1", "lh_1"),
              _buildBusButton(context, "LH 2", "lh_2"),
              _buildBusButton(context, "MBH 1", "mbh_1"),
              _buildBusButton(context, "MBH 2", "mbh_2"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusButton(BuildContext context, String label, String busId) {
    return GestureDetector(
      onTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: BusPosition(busId: busId),
          withNavBar: true,
          pageTransitionAnimation: PageTransitionAnimation.cupertino,
        );
      },
      child: Container(
        height: 80,
        width: 120,
        decoration: BoxDecoration(
          color: pricol,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
