import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase_options.dart';
import 'package:ogs/services/landingservice/landingservice.dart';
import 'package:ogs/services/notifications_service.dart';
import 'package:ogs/services/points_service.dart';
import 'package:ogs/services/screen_time_tracker.dart';
import 'package:provider/provider.dart';
import 'form_response/form_response.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:ogs/pages/fnu_hotel.dart';
import 'package:ogs/pages/fnu_movies.dart';
import 'package:ogs/pages/events_view_all.dart';
import 'package:ogs/pages/ads_view_all.dart';
import 'package:ogs/pages/fnu_restaurants.dart';
import 'package:ogs/pages/bus.dart';
import 'package:ogs/pages/s_points_page.dart';
import 'package:ogs/pages/s_vouchers.dart';

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
          page = const BusTrackPage();
          break;
        case 'event':
          page = const EventsViewAll();
          break;
        case 'movie':
          page = const MoviesPage();
          break;
        case 'hotel':
          page = const HotelPage();
          break;
        case 'restaurant':
          page = const RestaurantsPage();
          break;
        case 'offer':
          page = const AdsViewAll();
          break;
        case 'points':
          page = PointsScreen();
          break;
        case 'voucher':
          page = const VouchersScreen();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ScreenTimeTracker _screenTimeTracker = ScreenTimeTracker();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
      _initializeUserServices(user.uid);
      } else {
        // User logged out, dispose screen time tracker
        _screenTimeTracker.dispose();
      }
    });
  }

  Future<void> _initializeUserServices(String userId) async {
    try {
      // Initialize screen time tracking
      _screenTimeTracker.initialize(userId);

      // Initialize user points (this will grant signup voucher if first time)
      //await PointsService.initializeUserPoints(userId);

      // Award daily login points
      await PointsService.awardDailyLoginPoints(userId);

      print('User services initialized successfully for user: $userId');
    } catch (e) {
      print('Error initializing user services: $e');
    }
  }

  @override
  void dispose() {
    _screenTimeTracker.dispose();
    super.dispose();
  }

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
          )),
    );
  }
}

// Helper class to handle user authentication and services
class AuthServiceManager {
  static final ScreenTimeTracker _screenTimeTracker = ScreenTimeTracker();
  static String? _currentUserId;

  static Future<void> onUserLogin(String userId) async {
    try {
      if (_currentUserId != userId) {
        // Dispose previous user's tracker if different user
        if (_currentUserId != null) {
          _screenTimeTracker.dispose();
        }

        _currentUserId = userId;

        // Initialize services for new user
        _screenTimeTracker.initialize(userId);
        //await PointsService.initializeUserPoints(userId);

        print('Services initialized for user: $userId');
      }
    } catch (e) {
      print('Error in onUserLogin: $e');
    }
  }

  static void onUserLogout() {
    _screenTimeTracker.dispose();
    _currentUserId = null;
    print('User services disposed');
  }
}
