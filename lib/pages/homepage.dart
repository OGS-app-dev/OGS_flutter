import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/dbservices.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/comingsoon.dart';
import 'package:ogs/pages/notificationpage.dart';
import 'package:ogs/widgets/horizontalscrolltile.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _fireDb = FireDb();

  PersistentTabController? tabController;

  User? currentUser;
  @override
  void initState() {
    super.initState();
    tabController =
        Provider.of<FormResponse>(context, listen: false).tabController;
    currentUser = _fireDb.getCurrentUser();
  }

  List images = [
    "lib/assets/images/img1.jpg",
    "lib/assets/images/img2.jpg",
    "lib/assets/images/img3.jpg",
    "lib/assets/images/img4.jpg",
    "lib/assets/images/img5.jpg",
    "lib/assets/images/img6.jpg"
  ];

  List placeNames = [
    "Lions Park",
    "square",
    "sm street",
    "waterfalls",
    "beach"
  ];

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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30), color: pricol),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                "Hello, ",
                style: GoogleFonts.outfit(
                    color: const Color.fromARGB(255, 16, 34, 112),
                    fontWeight: FontWeight.w400,
                    fontSize: 15),
              ),
            ),
            FutureBuilder(
              future: _fireDb.getUserDetails(currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SpinKitThreeBounce(
                    size: 18,
                    color: pricol,
                  );
                }

                var data = snapshot.data;
                //print(data!['username']);
                return Text(
                  data!['username'],
                  style: GoogleFonts.outfit(
                    color: const Color.fromARGB(255, 16, 34, 112),
                    fontSize: 23,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
            /*Text(
              "Niara!",
              style: GoogleFonts.outfit(
                color: const Color.fromARGB(255, 16, 34, 112),
                fontSize: 23,
                fontWeight: FontWeight.w400,
              ),
            ),*/
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
      //drawer: const Mydrawer(),
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
                              'Good morning,',
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
                              )
                              //Image.asset('lib/assets/icons/sun.png',height: 50,width: 80,),

                              ),
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
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          height: 0.06,
                          letterSpacing: 0.50,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View All',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF292931),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const ComingSoon(),
                              withNavBar: false,
                              pageTransitionAnimation:
                                  PageTransitionAnimation.cupertino,
                            );
                          },
                          child: SizedBox(
                              height: 40,
                              child: Image.asset(
                                'lib/assets/icons/petrol.png',
                                color: pricol,
                              )),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Petrol",
                          style: GoogleFonts.outfit(color: pricol),
                        ),
                        Text(
                          "Pumps",
                          style: GoogleFonts.outfit(color: pricol),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const ComingSoon(),
                              withNavBar: false,
                              pageTransitionAnimation:
                                  PageTransitionAnimation.cupertino,
                            );
                          },
                          child: SizedBox(
                              height: 40,
                              child: Image.asset(
                                'lib/assets/icons/res.png',
                                color: pricol,
                              )),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Restaurants",
                          style: GoogleFonts.outfit(color: pricol),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const ComingSoon(),
                              withNavBar: false,
                              pageTransitionAnimation:
                                  PageTransitionAnimation.cupertino,
                            );
                          },
                          child: SizedBox(
                              height: 40,
                              child: Image.asset(
                                'lib/assets/icons/hotel.png',
                                color: pricol,
                              )),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Hotels",
                          style: GoogleFonts.outfit(
                            color: pricol,
                          ),
                        )
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: const ComingSoon(),
                              withNavBar: false,
                              pageTransitionAnimation:
                                  PageTransitionAnimation.cupertino,
                            );
                          },
                          child: SizedBox(
                              height: 40,
                              child: Image.asset(
                                'lib/assets/icons/hospital.png',
                                color: pricol,
                              )),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Hospitals",
                          style: GoogleFonts.outfit(color: pricol),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onTap: () {
                    tabController?.jumpToTab(2);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * .88,
                    height: 112,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color.fromARGB(255, 245, 245, 245),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: const Icon(
                      LineIcons.mapMarker,
                      size: 50,
                      color: yel,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const HorizontalScrollTile(
                  height: 254,
                  width: 299,
                  outBorderRadius: 26,
                  hasChild: true,
                ),
                const SizedBox(
                  height: 18,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width / 25),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Events',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2C2C),
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          height: 0.06,
                          letterSpacing: 0.50,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'View All',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF292931),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                CarouselSlider(
                  items: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.amber,
                      ),
                      height: 200,
                      width: 500,
                      margin: const EdgeInsets.all(3),
                      child: const Center(child: Text("#Ad1")),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red,
                      ),
                      height: 200,
                      width: 500,
                      margin: const EdgeInsets.all(3),
                      child: const Center(child: Text("#Ad2")),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue,
                      ),
                      height: 200,
                      width: 450,
                      margin: const EdgeInsets.all(3),
                      child: const Center(child: Text("#Ad3")),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.green,
                      ),
                      height: 200,
                      width: 500,
                      margin: const EdgeInsets.all(3),
                      child: const Center(child: Text("#Ad4")),
                    ),
                  ],
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.16,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 1000,
                  child: MasonryGridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: placeNames.length,
                    gridDelegate:
                        const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Center(
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                images[index],
                              ))),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
