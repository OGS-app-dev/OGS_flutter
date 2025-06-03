import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/bus_position.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class TopTabPage extends StatefulWidget {
  const TopTabPage({super.key});

  @override
  State<TopTabPage> createState() => _TopTabPageState();
}

class _TopTabPageState extends State<TopTabPage> {
  PersistentTabController? tabController;

  // Screens now use busId instead of index
  List<Widget> screens() {
    return const [
      BusPosition(busId: 'lh_1'),
      BusPosition(busId: 'lh_2'),
      BusPosition(busId: 'mbh_1'),
      BusPosition(busId: 'mbh_2'),
    ];
  }

  List<PersistentBottomNavBarItem> navbarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.bus),
        title: 'LH 1',
        textStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: 1,
        ),
        activeColorPrimary: Colors.white,
        activeColorSecondary: yel,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.bus),
        title: 'LH 2',
        textStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: 1,
        ),
        activeColorPrimary: Colors.white,
        activeColorSecondary: yel,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.bus),
        title: 'MBH 1',
        textStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: 1,
        ),
        activeColorPrimary: Colors.white,
        activeColorSecondary: yel,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LineIcons.bus),
        title: 'MBH 2',
        textStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: 1,
        ),
        activeColorPrimary: Colors.white,
        activeColorSecondary: yel,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    tabController = PersistentTabController(initialIndex: 0);

    // Optional: If you still want to periodically update something else
    // Timer.periodic(const Duration(seconds: 5), (_) {
    //   // Example: polling or syncing
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PersistentTabView(
        controller: tabController,
        context,
        screens: screens(),
        items: navbarItems(),
        navBarStyle: NavBarStyle.style14,
        navBarHeight: 75,
        backgroundColor: pricol,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 5).copyWith(
          bottom: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: NavBarDecoration(
          colorBehindNavBar: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        resizeToAvoidBottomInset: true,
        handleAndroidBackButtonPress: false,
        stateManagement: true,
        onWillPop: (context) async => false,
      ),
    );
  }
}
