import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/dbservices.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/notificationpage.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:line_icons/line_icons.dart';


class Restaurant {
  final String name;
  final String location;
  final String imageUrl;

  Restaurant({
    required this.name,
    required this.location,
    required this.imageUrl,
  });
}

List<Restaurant> kattangalRestaurants = [
  Restaurant(
    name: 'OTM RESTAURANT',
    location: 'Kattangal, Near NITC, Kerala',
    imageUrl: 'assets/otm_restaurant.png', 
  ),
  Restaurant(
    name: 'FOODIES',
    location: 'Kattangal, Near NITC, Kerala',
    imageUrl: 'assets/foodies.png', 
  ),
  Restaurant(
    name: 'BROAST',
    location: 'Kattangal, Near NITC, Kerala',
    imageUrl: 'assets/broast.png', 
  ),
];

List<Restaurant> calicutRestaurants = [
  Restaurant(
    name: 'OTM RESTAURANT (C)',
    location: 'Calicut, Near Bus Stand, Kerala',
    imageUrl: 'assets/otm_restaurant.png', 
  ),
  Restaurant(
    name: 'FOODIES (C)',
    location: 'Calicut, City Center, Kerala',
    imageUrl: 'assets/foodies.png', 
  ),
  Restaurant(
    name: 'BROAST (C)',
    location: 'Calicut, Main Road, Kerala',
    imageUrl: 'assets/broast.png', 
  ),
];
// --------------------------------------------------------

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({
    super.key,
  });
  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final _fireDb = FireDb();

  PersistentTabController? tabController;

  String time = 'Good morning,';

  User? currentUser;

  @override
  void initState() {
    super.initState();
    time = getTime();
    tabController =
        Provider.of<FormResponse>(context, listen: false).tabController;
    currentUser = _fireDb.getCurrentUser();
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

  String getFirstName(DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
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

  Widget getProfileImage(DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
    Map<String, dynamic>? userData = docSnapshot?.data();
    
    if (userData != null && userData['profileImage'] != null) {
      // If user has profile image in database
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(userData['profileImage']),
        backgroundColor: pricol,
      );
    } else if (user?.photoURL != null) {
      // If Google sign-in photo exists
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(user!.photoURL!),
        backgroundColor: pricol,
      );
    } else {
      // Default icon
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
                      color: const Color.fromARGB(255, 16, 34, 112),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: const NotificationPage(),
                withNavBar: false,
                pageTransitionAnimation: PageTransitionAnimation.cupertino,
              );
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: const ShapeDecoration(
                color: Color(0xFFF5F5F5),
                shape: OvalBorder(),
                shadows: [
                  BoxShadow(
                    color: Color(0xFFFFE47C),
                    blurRadius: 6,
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
          const SizedBox(
            width: 30,
          )
        ],
      ),
      body: SingleChildScrollView( 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            "Search here...",
                            style: GoogleFonts.outfit(),
                          ),
                          const Spacer(),
                          const Icon(
                            CupertinoIcons.search,
                            color: yel,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44.53,
                      height: 42.68,
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(0.52, -0.85),
                          end: Alignment(-0.52, 0.85),
                          colors: [Color(0xFFFFCC00), Color(0xFFFFE47C)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadows: const [
                          BoxShadow(
                            color: Color(0xAAFFE47C),
                            blurRadius: 13,
                            offset: Offset(-4, 5),
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Image.asset(
                          'lib/assets/icons/filter.png',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
            
            // --- Restaurants in KATTANGAL Section ---
            _buildRestaurantSection('KATTANGAL', kattangalRestaurants),
          const  SizedBox(height: 20), 

            // --- Restaurants in CALICUT Section ---
            _buildRestaurantSection('CALICUT', calicutRestaurants),
           const  SizedBox(height: 20), 
          ],
        ),
      ),]
    )));
  }

  Widget _buildRestaurantSection(String title, List<Restaurant> restaurants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restaurants in $title',
                style:const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  print('View All tapped for $title');
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => AllRestaurantsPage(location: title)));
                },
                child:const Text(
                  'View All',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            padding:const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              return _buildRestaurantCard(restaurants[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Container(
      width: 150, 
      margin:const EdgeInsets.only(right: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset:const Offset(0, 3), 
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              restaurant.imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child:const  Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style:const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
             const   SizedBox(height: 4),
                Text(
                  restaurant.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}