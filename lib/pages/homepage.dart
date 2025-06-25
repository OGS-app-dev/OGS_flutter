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
import 'package:ogs/widgets/horizontalscrolltile.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:ogs/widgets/myevents.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/pages/fnu_restaurants.dart';
import 'package:ogs/pages/fnu_hotel.dart';
import 'package:ogs/pages/fnu_hospitals.dart';
import 'package:ogs/pages/fnu_movies.dart';
import 'package:ogs/pages/fnu_petrol.dart';
//import 'package:ogs/pages/events_view_all.dart';
import 'package:ogs/pages/ads_view_all.dart';
import 'package:ogs/pages/search.dart';
import 'package:ogs/pages/fnu_bank.dart';
import 'package:ogs/widgets/urlscard.dart';
import 'package:ogs/pages/urls_details.dart';
import 'package:ogs/pages/urs_view_all.dart';
import 'package:ogs/pages/s_profile_edit.dart';
import 'package:ogs/pages/profile_page_new_2.dart';
import 'package:ogs/widgets/events_urls.dart';
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _fireDb = FireDb();
  final TextEditingController _searchController = TextEditingController();

  PersistentTabController? tabController;
  String time = 'Good morning,';
  bool showAllFacilities = false;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    time = getTime();
    tabController =
        Provider.of<FormResponse>(context, listen: false).tabController;
    currentUser = _fireDb.getCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getTime() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (hour >= 0 && hour < 12) {
      return 'Good morning,'; // Morning
    } else if (hour >= 12 && hour < 15) {
      return 'Good afternoon,'; // Afternoon
    } else {
      return 'Good Evening,'; // Evening/Night
    }
  }

  String getFirstName(
      DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();

    if (userData != null && userData['name'] != null) {
      // If user data exists in database, use it
      return userData['name'].split(" ")[0];
    } else if (user?.displayName != null) {
      // If no database data but Google sign-in displayName exists
      return user!.displayName!.split(" ")[0];
    } else if (user?.email != null) {
      // Fallback to email username
      return user!.email!.split("@")[0];
    } else {
      // Final fallback
      return "User";
    }
  }

  Widget getProfileImage(
      DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();

    if (userData != null && userData['profileImage'] != null) {
      // If user has profile image in database
      return GestureDetector(
        onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen:const  ProfileScreen(),
                    withNavBar: true,
                    pageTransitionAnimation:
                        PageTransitionAnimation.cupertino,
                  );
                },
        child: CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(userData['profileImage']),
          backgroundColor: pricol,
        ),
      );
    } else if (user?.photoURL != null) {
      // If Google sign-in photo exists
      return GestureDetector(
        onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen:const  ProfileScreen(),
                    withNavBar: true,
                    pageTransitionAnimation:
                        PageTransitionAnimation.cupertino,
                  );
                },
        child: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(user!.photoURL!),
          backgroundColor: pricol,
        ),
      );
    } else {
      // Default icon
      return GestureDetector(
        onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen:const  ProfileScreen(),
                    withNavBar: true,
                    pageTransitionAnimation:
                        PageTransitionAnimation.cupertino,
                  );
                },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30), color: pricol),
          child: const Icon(
            CupertinoIcons.person_fill,
            color: Colors.white,
          ),
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

  Widget buildFacilityIcon({
    required String iconPath,
    required String label1,
    String? label2,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
              height: 40,
              child: Image.asset(
                iconPath,
                color: pricol,
              )),
        ),
        const SizedBox(height: 5),
        Text(
          label1,
          style: GoogleFonts.outfit(color: pricol),
        ),
        if (label2 != null)
          Text(
            label2,
            style: GoogleFonts.outfit(color: pricol),
          ),
      ],
    );
  }

  Widget _buildNotificationButton() {
  // Get current user ID
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  // If user is not logged in, show a simple notification button
  if (currentUserId == null) {
    return Container(
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
            // Navigate to login or show login prompt
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
    );
  }

  return StreamBuilder<QuerySnapshot>(
    // Get all notifications for the user (user-specific + global)
    stream: FirebaseFirestore.instance
        .collection('notifications')
        .where(Filter.or(
          Filter('userId', isEqualTo: currentUserId),
          Filter('isGlobal', isEqualTo: true),
        ))
        .snapshots(),
    builder: (context, snapshot) {
      bool hasUnread = false;
      
      if (snapshot.hasData && snapshot.data != null) {
        final docs = snapshot.data!.docs;
        
        // Check if there are any unread notifications
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final isGlobal = data['isGlobal'] == true;
          final isRead = data['isRead'] == true;
          final userId = data['userId'];
          final readBy = data['readBy'] as Map<String, dynamic>? ?? {};
          
          if (isGlobal) {
            // For global notifications, check if current user has read it
            // If readBy doesn't contain the user ID or it's false, it's unread
            if (readBy[currentUserId] != true) {
              hasUnread = true;
              break;
            }
          } else if (userId == currentUserId && !isRead) {
            // User-specific unread notifications
            hasUnread = true;
            break;
          }
        }
      }

      return Container(
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(11),
              child: GestureDetector(
                onTap: () {
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: NotificationPage(),
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
            // Red dot for unread notifications - only show if there are actual unread notifications
            if (hasUnread)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
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
            const SizedBox(
              width: 10,
            ),
            // Profile image that works for both regular and Google sign-in users
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
            const SizedBox(
              width: 10,
            ),
            // User name that works for both regular and Google sign-in users
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
        //here location
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                const SizedBox(
                  height: 20,
                ),
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
                    _buildNotificationButton(),
                  ],
                ),
                const SizedBox(
                  height: 35,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Facilities Near You',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2C2C),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 0.06,
                          letterSpacing: 0.50,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          
                          setState(() {
                            showAllFacilities = !showAllFacilities;
                          });
                        },
                        child: Text(
                          showAllFacilities ? 'Show Less' : 'See more',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color.fromARGB(255, 77, 172, 255),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                // First row of facilities (always visible)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildFacilityIcon(
                      iconPath: 'lib/assets/icons/movies.png',
                      label1: "Movies",
                      onTap: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: const MoviesPage(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                    ),
                    
                    buildFacilityIcon(
                      iconPath: 'lib/assets/icons/bank.png',
                      label1: "Banks",
                      onTap: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: const BankPage(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                    ),
                    buildFacilityIcon(
                      iconPath: 'lib/assets/icons/res.png',
                      label1: "Restaurants",
                      onTap: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: const RestaurantsPage(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                    ),
                    buildFacilityIcon(
                      iconPath: 'lib/assets/icons/hospital.png',
                      label1: "Hospitals",
                      onTap: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: const HospitalPage(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                    ),
                  ],
                ),
                // Second row of facilities (visible only when showAllFacilities is true)
                if (showAllFacilities)
                  Column(
                    children: [
                      const SizedBox(height: 25),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildFacilityIcon(
                            iconPath: 'lib/assets/icons/petrol.png',
                            label1: "Petrol",
                            label2: "Pumps",
                            onTap: () {
                              PersistentNavBarNavigator.pushNewScreen(
                                context,
                                screen: const PetrolPage(),
                                withNavBar: false,
                                pageTransitionAnimation:
                                    PageTransitionAnimation.cupertino,
                              );
                            },
                          ),
                          // Add more facilities here if needed
                              buildFacilityIcon(
                      iconPath: 'lib/assets/icons/hotel.png',
                      label1: "Hotels",
                      onTap: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: const HotelPage(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                    ),
                          const SizedBox(
                              width: 40), // Placeholder to maintain spacing
                          const SizedBox(
                              width: 40), // Placeholder to maintain spacing
                        ],
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 25,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Events happening',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2C2C),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 0.06,
                          letterSpacing: 0.50,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          PersistentNavBarNavigator.pushNewScreen(
                            context,
                            screen: const EventsViewAll(),
                            withNavBar: false,
                            pageTransitionAnimation:
                                PageTransitionAnimation.cupertino,
                          );
                        },
                        child: Text(
                          'View All',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color.fromARGB(255, 77, 172, 255),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Urlscard(),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Explore',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2C2C),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 0.06,
                          letterSpacing: 0.50,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          PersistentNavBarNavigator.pushNewScreen(
                            context,
                            screen: const AdsViewAll( height: 240,
                  width: 289,
                  outBorderRadius: 26,
                  hasChild: true,),
                            withNavBar: false,
                            pageTransitionAnimation:
                                PageTransitionAnimation.cupertino,
                          );
                        },
                        child: Text(
                          'View All',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: const Color.fromARGB(255, 77, 172, 255),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 0,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const HorizontalScrollTile(
                  height: 240,
                  width: 289,
                  outBorderRadius: 26,
                  hasChild: true,
                ),
                const SizedBox(
                  height: 20,
                ),
                const SizedBox(
                  height: 50,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}