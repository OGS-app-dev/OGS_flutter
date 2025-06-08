import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase_options.dart';
import 'package:ogs/services/landingservice/landingservice.dart';
import 'package:ogs/services/notifications_service.dart';
import 'package:provider/provider.dart';
import 'form_response/form_response.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:ogs/pages/fnu_hotel.dart';
import 'package:ogs/pages/fnu_movies.dart';
import 'package:ogs/pages/events_view_all.dart';
import 'package:ogs/pages/ads_view_all.dart';
import 'package:ogs/pages/fnu_restaurants.dart';
import 'package:ogs/pages/bus.dart';



// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize notification service
await OGSNotificationService.initialize();
  
  // Setup notification handling
  setupNotificationHandling();
  
  runApp(const MyApp());
}

void setupNotificationHandling() {
  OGSNotificationService.onNotificationTap = (type, data) {
    // Use the global navigator key to navigate
    final context = navigatorKey.currentContext;
    if (context != null) {
      Widget? page;
      
      switch (type) {
        case 'bus':
          page =const BusTrackPage(); 
          break;
        case 'event':
          page =const  EventsViewAll();
          break;
        case 'movie':
          page =const  MoviesPage(); 
          break;
        case 'hotel':
          page =const  HotelPage(); 
          break;
        case 'restaurant':
          page = const RestaurantsPage(); 
          break;
        case 'offer':
          page =const  AdsViewAll(); 
          break;
        default:
          return;
      }
      
      if (page != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => page!),
        );
      }
    }
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FormResponse>(
      create: (context) => FormResponse(),
      child: MaterialApp(
        navigatorKey: navigatorKey, // Add the global navigator key
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Helvetica', 
          primarySwatch: Colors.blue,
        ),
        home: AnimatedSplashScreen(
          splash: "lib/assets/icons/ani.gif",
          nextScreen: const Landing(),
          duration: 3000,
          backgroundColor: yel,
          centered: true,
          splashIconSize: 200,
        )
      ),
    );
  }
}