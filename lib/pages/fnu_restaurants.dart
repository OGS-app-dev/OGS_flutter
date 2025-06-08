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
import 'package:ogs/models/restaurant_model.dart';
import 'package:ogs/pages/fnu_view_all.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:ogs/pages/search.dart';



class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({
    super.key,
  });
  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  final _fireDb = FireDb();
final TextEditingController _searchController = TextEditingController();
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
  PersistentTabController? tabController;

  String time = 'Good morning,';

  User? currentUser;
  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $url')),
        );
      }
    }
  }

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
      return userData['name'].split(" ")[0];
    } else if (user?.displayName != null) {
      return user!.displayName!.split(" ")[0];
    } else if (user?.email != null) {
      return user!.email!.split("@")[0];
    } else {
      return "User";
    }
  }

  Widget getProfileImage(DocumentSnapshot<Map<String, dynamic>>? docSnapshot, User? user) {
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
  Widget _buildNotificationButton() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots(),
    builder: (context, snapshot) {
      bool hasUnread = false;
      
      if (snapshot.hasData && snapshot.data != null) {
        hasUnread = snapshot.data!.docs.isNotEmpty;
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
            // Simple red dot for unread notifications
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
                screen:  NotificationPage(),
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
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) => _performSearch(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          hintText: "Explore Events and more....",
                          hintStyle: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: _performSearch,
                            child: const Icon(
                              CupertinoIcons.search,
                              color: yel,
                              size: 20,
                            ),
                          ),
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildNotificationButton()
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
            
            // --- Restaurants in KATTANGAL Section ---
            _buildFirebaseRestaurantSection('KATTANGAL', 'res_kattangal'),
            const SizedBox(height: 20), 

            // --- Restaurants in CALICUT Section ---
            _buildFirebaseRestaurantSection('CALICUT', 'res_calicut'),
            const SizedBox(height: 20), 
          ],
        ),
      ),]
    )));
  }

  Widget _buildFirebaseRestaurantSection(String title, String collectionName) {
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
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  print('View All tapped for $title');
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => AllRestaurantsPage(location: title)));
                  PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen:   ViewAllPage(pageTitle: 'Restaurants in $title', nameCollection: collectionName) ,
                              withNavBar: false,
                              pageTransitionAnimation:
                                  PageTransitionAnimation.cupertino,
                            );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.outfit(
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 230,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collectionName)
                .orderBy('name') 
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading restaurants',
                    style: GoogleFonts.outfit(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitThreeBounce(
                    size: 20,
                    color: pricol,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No restaurants found in $title',
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final restaurants = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: restaurants.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemBuilder: (context, index) {
                  final restaurant = Restaurant.fromFirestore(
                    restaurants[index] as DocumentSnapshot<Map<String, dynamic>>
                  );
                  return _buildRestaurantCard(restaurant);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
         if (restaurant.siteUrl != null && restaurant.siteUrl!.isNotEmpty) {
        _launchUrl(context, restaurant.siteUrl!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No website available for ${restaurant.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.2),
          //     spreadRadius: 1,
          //     blurRadius: 5,
          //     offset: const Offset(0, 3),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: restaurant.imageUrl.startsWith('http')
                      ? Image.network(
                          restaurant.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.fill,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: pricol,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 130,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        )
                      : Image.asset(
                          restaurant.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            );
                          },
                        ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (restaurant.rating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.rating!.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      restaurant.location,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}