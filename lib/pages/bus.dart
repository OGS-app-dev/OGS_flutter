import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/dbservices.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/notificationpage.dart';
import 'package:ogs/pages/bus_position_new.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/pages/search.dart';

class BusTrackPage extends StatefulWidget {
  const BusTrackPage({
    super.key,
  });

  @override
  State<BusTrackPage> createState() => _BusTrackPageState();
}

class _BusTrackPageState extends State<BusTrackPage> with SingleTickerProviderStateMixin {
  final _fireDb = FireDb();
  final TextEditingController _searchController = TextEditingController();

  PersistentTabController? tabController;
  late TabController _tabController;
  String time = 'Good morning,';
  bool showAllFacilities = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    time = getTime();
    tabController = Provider.of<FormResponse>(context, listen: false).tabController;
    currentUser = _fireDb.getCurrentUser();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String getTime() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (hour >= 0 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 15) {
      return 'Good afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  String getFirstName(
      DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();

    if (userData != null && userData['name'] != null) {
      return userData['name'].split(" ")[0];
    } else if (user?.displayName != null) {
      return user!.displayName!.split(" ")[0];
    } else if (user?.email != null) {
      return user!.email!.split("@")[0];
    } else {
      return "User";
    }
  }

  Widget getProfileImage(
      DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();

    if (userData != null && userData['profileImage'] != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(userData['profileImage']),
        backgroundColor: pricol,
      );
    } else if (user?.photoURL != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(user!.photoURL!),
        backgroundColor: pricol,
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30), color: pricol),
        child: const Icon(
          CupertinoIcons.person_fill,
          color: Colors.white,
        ),
      );
    }
  }

  void _performSearch() {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: UnifiedSearchPage(searchQuery: query),
        withNavBar: false,
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        bottomOpacity: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            FutureBuilder(
              future: _fireDb.getUserDetails(currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30), color: pricol),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white,
                    ),
                  );
                }

                var docSnapshot = snapshot.data;
                return getProfileImage(docSnapshot, currentUser);
              },
            ),
            const SizedBox(width: 10),
            Flexible(
              child: FutureBuilder(
                future: _fireDb.getUserDetails(currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SpinKitThreeBounce(
                      size: 10,
                      color: pricol,
                    );
                  }

                  var docSnapshot = snapshot.data;
                  String firstName = getFirstName(docSnapshot, currentUser);

                  return Text(
                    "Hello, $firstName!",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Color.fromARGB(255, 16, 34, 112),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width / 15),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 48,
                        width: 236,
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 10,
                              left: 0,
                              child: Text(
                                time,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFFCD01),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w400,
                                  height: 0.05,
                                  letterSpacing: -0.75,
                                ),
                              ),
                            ),
                            const Positioned(
                                right: 0,
                                top: 8,
                                child: Icon(
                                  LineIcons.sunAlt,
                                  size: 30,
                                  color: yel,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * .8,
                        height: 44,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x05000000),
                              blurRadius: 8,
                              offset: Offset(1, 8),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (value) => _performSearch(),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 12),
                            hintText: "Explore Events and more....",
                            hintStyle: GoogleFonts.outfit(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                        CupertinoIcons.xmark_circle_fill,
                                        color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    CupertinoIcons.search,
                                    color: yel,
                                  ),
                                  onPressed: _performSearch,
                                ),
                              ],
                            ),
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        width: 44.53,
                        height: 42.68,
                        decoration: ShapeDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(0.52, -0.85),
                            end: Alignment(-0.52, 0.85),
                            colors: [Color(0xFFFFCC00), Color(0xFFFFCC00)],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0xFFFFCC00),
                              blurRadius: 22,
                              offset: Offset(-4, 5),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: GestureDetector(
                            onTap: () {
                              PersistentNavBarNavigator.pushNewScreen(
                                context,
                                screen: const NotificationPage(),
                                withNavBar: false,
                                pageTransitionAnimation:
                                    PageTransitionAnimation.cupertino,
                              );
                            },
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: const ShapeDecoration(
                                color: Color(0xFFFFCC00),
                                shape: CircleBorder(),
                                shadows: [
                                  BoxShadow(
                                    color: Color(0xFFFFCC00),
                                    blurRadius: 0,
                                    offset: Offset(0, 4),
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.bell,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bus Tracking Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width / 15),
                      child: Text(
                        'Bus Tracking',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
            // Tab Bar
            Container(
  color: const Color.fromARGB(255, 255, 235, 155),
  child: TabBar(
    controller: _tabController,
    indicatorColor: Colors.transparent, 
    indicator: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(4), 
    ),
    indicatorPadding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5), 
    indicatorSize: TabBarIndicatorSize.tab, 
    labelColor: Colors.white,
    unselectedLabelColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
    labelStyle: GoogleFonts.outfit(
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
    labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
    isScrollable: false,
    tabs: const [
      Tab(text: ' LH BUS-1 '),
      Tab(text: ' LH BUS-2 '),
      Tab(text: ' MBH BUS-1 '),
      Tab(text: ' MBH BUS-2 '),
    ],
  ),
),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  BusPosition(busId: 'lh_1'),
                  BusPosition(busId: 'lh_2'),
                  BusPosition(busId: 'mbh_1'),
                  BusPosition(busId: 'mbh_2'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}