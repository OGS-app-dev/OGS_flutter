import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/homepage.dart';
import 'package:ogs/pages/loading_screen.dart';
import 'package:ogs/pages/profilepage_new.dart';
import 'package:ogs/pages/topnavpage.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  PersistentTabController? tabController=PersistentTabController(initialIndex: 0);

  List<Widget> screens() {
    return [
      const HomePage(),
      const TopTabPage(),
      //TrackBusPage(),
      //const BusPosition(),
     const LoadingScreen(),
      const UserProfilePage(),
    ];
  }

  List<PersistentBottomNavBarItem> navbaritems() {
    return [
      PersistentBottomNavBarItem(
          icon: const Icon(
            CupertinoIcons.home,
          ),
          title: 'Home',
          textStyle: GoogleFonts.outfit(
              color: pricol,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
      PersistentBottomNavBarItem(
          icon: const Icon(LineIcons.bus),
          title: 'Friends',
          textStyle: GoogleFonts.outfit(
              color: pricol,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
      PersistentBottomNavBarItem(
          icon: const Icon(
            LineIcons.mapMarker,
            size: 30,
          ),
          title: 'location',
          textStyle: GoogleFonts.outfit(
              color: pricol,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
      PersistentBottomNavBarItem(
          icon: const Icon(
            Icons.person,
            size: 35,
          ),
          title: 'Account',
          textStyle: GoogleFonts.outfit(
              color: pricol,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 1),
          activeColorPrimary: Colors.white,
          activeColorSecondary: yel),
    ];
  }

  @override
  void initState() {
    tabController = PersistentTabController(initialIndex: 0);
    tabController = Provider.of<FormResponse>(context, listen: false).tabController;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
        navBarStyle: NavBarStyle.style12,
        resizeToAvoidBottomInset: true,
        navBarHeight: 75,
        padding: const EdgeInsets.only(
          top: 12,
          left: 8,
          right: 8,
          bottom: 6,
        ),
        margin: const EdgeInsets.all(.001),

        decoration: const NavBarDecoration(
            colorBehindNavBar: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            )),
        //handleAndroidBackButtonPress: true,
        backgroundColor: pricol,
        stateManagement: true,
      ),
    );
  }
}
