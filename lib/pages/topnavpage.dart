import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/bus_position.dart';

import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopTabPage extends StatefulWidget {
  const TopTabPage({super.key});

  @override
  State<TopTabPage> createState() => _TopTabPageState();
}

class _TopTabPageState extends State<TopTabPage> {
  PersistentTabController? tabController;

  List<Widget> screens() {
    return [
      const BusPosition(index: 0),
      const BusPosition(index: 1),
      const BusPosition(index: 2),
      const BusPosition(index: 3),
    ];
  }

  List<PersistentBottomNavBarItem> navbaritems() {
    return [
      PersistentBottomNavBarItem(
          icon: const Icon(LineIcons.bus),
          title: 'LH 1',
          textStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 15,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
      PersistentBottomNavBarItem(
          icon: const Icon(LineIcons.bus),
          title: 'LH 2',
          textStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 15,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
      PersistentBottomNavBarItem(
          icon: const Icon(LineIcons.bus),
          title: 'MBH 1',
          textStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 15,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
      PersistentBottomNavBarItem(
          icon: const Icon(LineIcons.bus),
          title: 'MBH 2',
          textStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 15,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
    ];
  }

  @override
  void initState() {
    tabController = PersistentTabController(initialIndex: 0);
    //tabController = Provider.of<FormResponse>(context, listen: false).tabController;
    final locationProvider = Provider.of<FormResponse>(context, listen: false);
    Timer.periodic(const Duration(seconds: 5), (Timer t) {
      locationProvider.updateTempBusLoc();
    });
    // setState(() {

    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).size.height * .82;

    return Scaffold(
      backgroundColor: Colors.white,
      body: PersistentTabView(
        controller: tabController,
        onWillPop: (context) async {
          return false;
        },
        handleAndroidBackButtonPress: false,
        context,
        screens: screens(),

        items: navbaritems(),
        navBarStyle: NavBarStyle.style14,
        resizeToAvoidBottomInset: true,
        navBarHeight: 75,
        padding: const EdgeInsets.all(10),
        margin: EdgeInsets.only(
          right: 5,
          left: 5,
          bottom: bottom,
        ),

        decoration: NavBarDecoration(
            colorBehindNavBar: Colors.white,
            borderRadius: BorderRadius.circular(40)),
        //handleAndroidBackButtonPress: true,
        backgroundColor: pricol,
        stateManagement: true,
      ),
    );
  }
}
